terraform {
  required_version = "~> 1.16.4"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

resource "random_pet" "demo" {
  length    = 2
  separator = "-"
}

output "nombre_generado" {
  value = random_pet.demo.id
}