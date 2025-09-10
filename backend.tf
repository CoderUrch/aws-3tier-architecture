terraform {
  cloud {

    organization = "rover"

    workspaces {
      name = "local"
    }
  }
}