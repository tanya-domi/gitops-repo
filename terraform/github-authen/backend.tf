terraform {
  backend "gcs" {
    bucket  = "tanya-terraform-state"
    prefix  = "terraform/state"
  }
}

