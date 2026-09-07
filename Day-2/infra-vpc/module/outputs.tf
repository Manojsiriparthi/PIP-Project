output "vpc_id" { value = aws_vpc.this.id }
output "vpc_cidr" { value = aws_vpc.this.cidr_block }
output "public_subnet_ids" { value = [for k in sort(keys(aws_subnet.public)) : aws_subnet.public[k].id] }
output "app_subnet_ids" { value = [for k in sort(keys(aws_subnet.app)) : aws_subnet.app[k].id] }
output "data_subnet_ids" { value = [for k in sort(keys(aws_subnet.data)) : aws_subnet.data[k].id] }
output "public_route_table_id" { value = aws_route_table.public.id }
output "app_route_table_ids" { value = { for k, v in aws_route_table.app : k => v.id } }
output "data_route_table_ids" { value = { for k, v in aws_route_table.data : k => v.id } }
output "nat_gateway_ids" { value = { for k, v in aws_nat_gateway.this : k => v.id } }
output "security_group_ids" { value = { alb = aws_security_group.alb.id, app = aws_security_group.app.id, data = aws_security_group.data.id, endpoint = aws_security_group.endpoint.id } }
output "public_nacl_id" { value = aws_network_acl.public.id }
output "private_nacl_id" { value = aws_network_acl.private.id }
output "s3_endpoint_id" { value = try(aws_vpc_endpoint.s3[0].id, null) }
output "sqs_endpoint_id" { value = try(aws_vpc_endpoint.sqs[0].id, null) }
output "sns_endpoint_id" { value = try(aws_vpc_endpoint.sns[0].id, null) }
output "flow_log_bucket" { value = try(aws_s3_bucket.flow_logs[0].bucket, null) }
output "flow_log_id" { value = try(aws_flow_log.this[0].id, null) }
