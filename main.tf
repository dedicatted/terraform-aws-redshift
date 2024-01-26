data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source             = "github.com/terraform-aws-modules/terraform-aws-vpc"
  name               = var.vpc_name
  cidr               = var.cidr_block
  azs                = slice(data.aws_availability_zones.available.names, 0, 1)
  public_subnets     = [cidrsubnet(var.cidr_block, 8, 3), cidrsubnet(var.cidr_block, 8, 4), cidrsubnet(var.cidr_block, 8, 5)]
  private_subnets    = [cidrsubnet(var.cidr_block, 8, 0), cidrsubnet(var.cidr_block, 8, 1), cidrsubnet(var.cidr_block, 8, 2)]
  enable_nat_gateway = true
  single_nat_gateway = true
}
module "redshift" {
  source  = "terraform-aws-modules/redshift/aws"

  cluster_identifier    = "example"
  allow_version_upgrade = true
  node_type             = "ra3.xlplus"
  number_of_nodes       = 3

  database_name          = "mydb"
  master_username        = "mydbuser"
  create_random_password = false
  master_password        = "MySecretPassw0rd1!" # Do better!
  manage_master_password = false

  encrypted   = true
  kms_key_arn = "arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab"

  enhanced_vpc_routing   = true
  vpc_security_group_ids = ["sg-12345678"]
  subnet_ids             = module.vpc.private_subnets

  availability_zone_relocation_enabled = true

  snapshot_copy = {
    destination_region = "us-east-1"
    grant_name         = "example-grant"
  }

  logging = {
    enable        = true
    bucket_name   = "my-s3-log-bucket"
    s3_key_prefix = "example/"
  }


  # Endpoint access
  create_endpoint_access          = true
  endpoint_name                   = "example-example"
  endpoint_subnet_group_name      = "example-subnet-group"
  endpoint_vpc_security_group_ids = ["sg-12345678"]

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}