resource "aws_dynamodb_table" "cliente" {
  name           = "cliente"
  billing_mode   = "PROVISIONED"
  read_capacity  = "${var.read_capacity}"
  write_capacity = "${var.write_capacity}"
  hash_key       = "numeroCliente"
 
  point_in_time_recovery {
    enabled = true
  }
 
  server_side_encryption {
    enabled = true
  }
 
  attribute {
    name = "numeroCliente"
    type = "S"
  }
 
  tags = {
    Name        = "cliente"
    Environment = "${var.env}"
    pep         = "ms-mfacore"
    sigla       = "mfacore"
    project     = "mfa"
    region      = "sa-east-1"
    golive      = "false"
    function    = "backend"
    service     = "database"
    owner       = "dbas"
  }
}

resource "aws_dynamodb_table" "whitelist" {
  name           = "whitelist"
  billing_mode   = "PROVISIONED"
  read_capacity  = "${var.read_capacity}"
  write_capacity = "${var.write_capacity}"
  hash_key       = "usuarioId"
 
  point_in_time_recovery {
    enabled = true
  }
 
  server_side_encryption {
    enabled = true
  }
 
  attribute {
    name = "usuarioId"
    type = "S"
  }
 
  tags = {
    Name        = "cliente"
    Environment = "${var.env}"
    pep         = "ms-mfacore"
    sigla       = "mfacore"
    project     = "mfa"
    region      = "sa-east-1"
    golive      = "false"
    function    = "backend"
    service     = "database"
    owner       = "dbas"
  }
}