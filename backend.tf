terraform {
  backend "gcs" {
    bucket = "tf-clearblade"
    prefix = "terraform/state"
  }
}