# Supervision déployée à part : elle doit survivre à la destruction du site.
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.6"
    }
  }
}

provider "docker" {}

resource "docker_image" "kuma" {
  name         = "louislam/uptime-kuma:1"
  keep_locally = true
}

data "docker_network" "front" {
  name = "hopla-front"
}

resource "docker_container" "kuma" {
  name  = "hopla-supervision"
  image = docker_image.kuma.image_id

  ports {
    internal = 3001
    external = 3001
  }

  networks_advanced {
    name = data.docker_network.front.name
  }
}
