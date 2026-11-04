# Hopla Market décrit comme du code : on déclare le résultat voulu, pas les étapes.

# --- Réseaux -----------------------------------------------------------------
resource "docker_network" "front" {
  name = "hopla-front"
}

resource "docker_network" "back" {
  name = "hopla-back"
}

# --- Images ------------------------------------------------------------------
resource "docker_image" "serveur" {
  name         = "python:3.12-slim"
  keep_locally = true
}

resource "docker_image" "nginx" {
  name         = "nginx:alpine"
  keep_locally = true
}

resource "docker_image" "postgres" {
  name         = "postgres:16-alpine"
  keep_locally = true
}

# --- Serveurs web : vides ici, Ansible les configure ensuite ------------------
resource "docker_container" "front" {
  count   = var.front_count
  name    = "hopla-front-${count.index + 1}"
  image   = docker_image.serveur.image_id
  command = ["sleep", "infinity"]
  memory  = 256

  networks_advanced {
    name = docker_network.front.name
  }

  networks_advanced {
    name = docker_network.back.name
  }
}

# --- Load balancer : le point d'entrée unique du site -------------------------
resource "docker_container" "lb" {
  name  = "hopla-lb"
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = 8080
  }

  upload {
    file = "/etc/nginx/conf.d/default.conf"
    content = templatefile("${path.module}/templates/lb.conf.tftpl", {
      fronts = docker_container.front[*].name
    })
  }

  networks_advanced {
    name = docker_network.front.name
  }
}

# --- Base de données : uniquement sur le réseau arrière -----------------------
resource "docker_container" "db" {
  name   = "hopla-db"
  image  = docker_image.postgres.image_id
  memory = var.db_memory_mb
  env    = ["POSTGRES_PASSWORD=${var.db_password}", "POSTGRES_DB=hopla"]

  networks_advanced {
    name = docker_network.back.name
  }
}

# --- Inventaire généré pour Ansible : Terraform crée, Ansible configure --------
resource "local_file" "inventaire" {
  filename = "${path.module}/../03-ansible/inventory.ini"
  content = templatefile("${path.module}/templates/inventory.tftpl", {
    fronts = docker_container.front[*].name
  })
}
