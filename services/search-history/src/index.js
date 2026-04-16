const express = require('express');
const AWS = require('aws-sdk');

const app = express();
app.use(express.json());

const PORT = 3001;
const TABLE_NAME = process.env.DYNAMODB_TABLE || 'search-history';

const dynamodb = new AWS.DynamoDB.DocumentClient({
  region: process.env.AWS_REGION || 'us-east-1'
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'search-history' });
});

// Save a search
app.post('/api/history', async (req, res) => {
  const { city, searchedAt } = req.body;

  try {
    await dynamodb.put({
      TableName: TABLE_NAME,
      Item: {
        userId: 'default-user',  // simplified for demo
        searchedAt: searchedAt || new Date().toISOString(),
        city: city
      }
    }).promise();

    res.json({ status: 'saved' });
  } catch (err) {
    console.error('Error saving:', err);
    res.status(500).json({ error: 'Failed to save' });
  }
});

// Get search history
app.get('/api/history', async (req, res) => {
  try {
    const result = await dynamodb.query({
      TableName: TABLE_NAME,
      KeyConditionExpression: 'userId = :uid',
      ExpressionAttributeValues: { ':uid': 'default-user' },
      ScanIndexForward: false,  // newest first
      Limit: 20
    }).promise();

    res.json({ searches: result.Items });
  } catch (err) {
    console.error('Error querying:', err);
    res.status(500).json({ error: 'Failed to get history' });
  }
});

app.listen(PORT, () => console.log(`Search History running on port ${PORT}`));