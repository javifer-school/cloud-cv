# Local backend for state management
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
