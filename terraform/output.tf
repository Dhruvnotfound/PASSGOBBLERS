# Output the API URL
output "api_url" {
  value = "${aws_api_gateway_deployment.secrets_api_deployment.invoke_url}/secrets"
}