//--------------------------------------------------------------------
// Modules
module "elasticsearch" {
  source  = "terraform.testecorp.cloud/teste/elasticsearch/aws"
  version = "1.1.4"

  cloudWatchLogGroup = "elasticsearch"
  descricao_sigla = "Multi Factor Authentication"
  domain = "mfacore-elk"
  golive = "false"
  owner_projeto = "devops"
  pep = 2565
  project = "mfacore"
  sigla_sistemica = "MFA"
  subnets = "${var.app_subnet_1},${var.app_subnet_2}"
  vpcID = "${var.vpcid}"
  instance_type = "${var.es_instance_type}"
  instance_count = "${var.es_instance_count}"
  dedicated_master_type = "${var.es_master_instance_type}"
  dedicated_master_count = "${var.es_master_instance_count}"
}