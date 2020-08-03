provider "aws" {
  version    = "~> 2.44.0"
  access_key = var.access_key 
  secret_key = var.secret_key
  region     = var.region
}

provider "template" {
  //version    = "1.0.0"
  version    = "2.1"
}

provider "random" {
  version    = "2.1.0"
}