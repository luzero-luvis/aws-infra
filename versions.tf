terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.9.0"
    }
    local = {
      source = "hashicorp/local"
      version = "~> 2.5"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}
