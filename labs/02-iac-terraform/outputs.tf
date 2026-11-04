output "serveurs_web" {
  description = "Noms des serveurs web créés"
  value       = docker_container.front[*].name
}

output "site" {
  description = "Adresse locale du site"
  value       = "http://localhost:8080"
}
