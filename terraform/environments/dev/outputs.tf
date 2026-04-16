output "cluster_name" {
  value = module.eks.cluster_name
}

output "ecr_weather_api_url" {
  value = module.ecr_weather_api.repository_url
}

output "ecr_search_history_url" {
  value = module.ecr_search_history.repository_url
}

output "rds_endpoint" {
  value = module.rds.endpoint
}