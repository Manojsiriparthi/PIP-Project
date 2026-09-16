output "instance_ids_by_region" {
  description = "EC2 instance IDs grouped by region."
  value = {
    ap_south_1     = module.ap_south_1.instance_ids
    us_east_1      = module.us_east_1.instance_ids
    eu_west_1      = module.eu_west_1.instance_ids
    ap_southeast_1 = module.ap_southeast_1.instance_ids
  }
}

output "private_ips_by_region" {
  description = "Private IPs grouped by region."
  value = {
    ap_south_1     = module.ap_south_1.private_ips
    us_east_1      = module.us_east_1.private_ips
    eu_west_1      = module.eu_west_1.private_ips
    ap_southeast_1 = module.ap_southeast_1.private_ips
  }
}

output "instance_profile_name" {
  value = aws_iam_instance_profile.benchmark.name
}

output "iam_role_name" {
  value = aws_iam_role.benchmark.name
}
