provider "aws" {
  region  = "sa-east-1"
}

provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
}