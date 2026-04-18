const express = require('express');
const { Pool } = require('pg');
const AWS = require('aws-sdk');

const app = express();
app.use(express.json());

const PORT = 3000;
const secretsManager = new AWS.SecretsManager({ region: process.env.AWS_REGION || 'us-east-1' });

let dbPool;

async function getSecret(secretName) {
  const result = await secretsManager.getSecretValue({ SecretId: secretName }).promise();
  return JSON.parse(result.SecretString);
}

async function initDb() {
  const creds = await getSecret(process.env.DB_SECRET_NAME || 'weather-api/db');
  dbPool = new Pool({
    host: creds.host.split(':')[0],  // remove port from endpoint
    port: parseInt(creds.port),
    user: creds.username,
    password: creds.password,
    database: creds.dbname,
    ssl: {
      rejectUnauthorized: false
    }
  });

  // Create cache table if not exists
  await dbPool.query(`
    CREATE TABLE IF NOT EXISTS weather_cache (
      city VARCHAR(100) PRIMARY KEY,
      data JSONB NOT NULL,
      cached_at TIMESTAMP DEFAULT NOW()
    )
  `);
  console.log('Database connected and table ready');
}

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'weather-api', version: 'v2' });
});

// Get weather for a city
app.get('/api/weather/:city', async (req, res) => {
  const city = req.params.city.toLowerCase();

  try {
    // Check cache first (last 30 minutes)
    const cached = await dbPool.query(
      "SELECT data FROM weather_cache WHERE city = $1 AND cached_at > NOW() - INTERVAL '30 minutes'",
      [city]
    );

    if (cached.rows.length > 0) {
      console.log(`Cache hit for ${city}`);
      return res.json({ source: 'cache', data: cached.rows[0].data });
    }

    // Cache miss — call OpenWeatherMap
    console.log(`Cache miss for ${city}, calling API`);
    const apiSecret = await getSecret(process.env.OPENWEATHER_SECRET_NAME || 'weather-api/openweather');

    const fetch = (await import('node-fetch')).default;
    const response = await fetch(
      `https://api.openweathermap.org/data/2.5/weather?q=${city}&appid=${apiSecret.api_key}&units=imperial`
    );
    const weatherData = await response.json();

    if (weatherData.cod !== 200) {
      return res.status(404).json({ error: 'City not found' });
    }

    // Save to cache
    await dbPool.query(
      'INSERT INTO weather_cache (city, data, cached_at) VALUES ($1, $2, NOW()) ON CONFLICT (city) DO UPDATE SET data = $2, cached_at = NOW()',
      [city, JSON.stringify(weatherData)]
    );

    // Call search history service
    try {
      await fetch(`http://search-history.search-history.svc.cluster.local:3001/api/history`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ city, searchedAt: new Date().toISOString() })
      });
    } catch (e) {
      console.log('Could not log to search history:', e.message);
    }

    res.json({ source: 'api', data: weatherData });
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Start server
initDb().then(() => {
  app.listen(PORT, () => console.log(`Weather API running on port ${PORT}`));
}).catch(err => {
  console.error('Failed to start:', err);
  process.exit(1);
});