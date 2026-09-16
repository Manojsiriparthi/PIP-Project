output "vpc_id" { value = module.vpc.vpc_id }
output "vpc_cidr" { value = module.vpc.vpc_cidr }
output "public_subnet_ids" { value = module.vpc.public_subnet_ids }
output "private_app_subnet_ids" { value = module.vpc.app_subnet_ids }
output "private_data_subnet_ids" { value = module.vpc.data_subnet_ids }
output "route_tables" {
  value = {
    public = module.vpc.public_route_table_id
    app    = module.vpc.app_route_table_ids
    data   = module.vpc.data_route_table_ids
  }
}
output "security_groups" { value = module.vpc.security_group_ids }
output "nacls" { value = { public = module.vpc.public_nacl_id, private = module.vpc.private_nacl_id } }
output "endpoints" { value = { s3 = module.vpc.s3_endpoint_id, sqs = module.vpc.sqs_endpoint_id, sns = module.vpc.sns_endpoint_id } }
output "flow_logging" { value = { bucket = module.vpc.flow_log_bucket, flow_log_id = module.vpc.flow_log_id } }
