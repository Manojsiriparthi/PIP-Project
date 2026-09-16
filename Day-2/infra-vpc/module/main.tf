locals {
  common_tags = {
    Project     = "PIP"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "flow_logs" {
  count = var.enable_s3_flow_logs ? 1 : 0

  statement {
    sid    = "AWSLogDeliveryAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.flow_logs[0].arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "AWSLogDeliveryWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.flow_logs[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(local.common_tags, { Name = "${var.name}-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "${var.name}-igw" })
}

resource "aws_subnet" "public" {
  for_each = { for i, cidr in var.public_subnet_cidrs : var.availability_zones[i] => cidr }

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = true
  tags = merge(local.common_tags, {
    Name = "${var.name}-public-${replace(each.key, var.region, "")}" 
  })
}

resource "aws_subnet" "app" {
  for_each = { for i, cidr in var.private_app_subnet_cidrs : var.availability_zones[i] => cidr }

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value
  tags = merge(local.common_tags, {
    Name = "${var.name}-app-${replace(each.key, var.region, "")}" 
  })
}

resource "aws_subnet" "data" {
  for_each = { for i, cidr in var.private_data_subnet_cidrs : var.availability_zones[i] => cidr }

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value
  tags = merge(local.common_tags, {
    Name = "${var.name}-data-${replace(each.key, var.region, "")}" 
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(local.common_tags, { Name = "${var.name}-rt-public" })
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  for_each = var.enable_nat_gateway && !var.single_nat_gateway ? aws_subnet.public : (var.enable_nat_gateway && var.single_nat_gateway ? { first = aws_subnet.public[var.availability_zones[0]] } : {})
  domain   = "vpc"
  tags     = merge(local.common_tags, { Name = "${var.name}-nat-eip-${each.key}" })
}

resource "aws_nat_gateway" "this" {
  for_each = var.enable_nat_gateway && !var.single_nat_gateway ? aws_subnet.public : (var.enable_nat_gateway && var.single_nat_gateway ? { first = aws_subnet.public[var.availability_zones[0]] } : {})

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id
  depends_on    = [aws_internet_gateway.this]
  tags          = merge(local.common_tags, { Name = "${var.name}-nat-${each.key}" })
}

resource "aws_route_table" "app" {
  for_each = aws_subnet.app
  vpc_id   = aws_vpc.this.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block = "0.0.0.0/0"
      nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.this["first"].id : aws_nat_gateway.this[each.key].id
    }
  }

  tags = merge(local.common_tags, { Name = "${var.name}-rt-app-${replace(each.key, var.region, "")}" })
}

resource "aws_route_table_association" "app" {
  for_each       = aws_subnet.app
  subnet_id      = each.value.id
  route_table_id = aws_route_table.app[each.key].id
}

resource "aws_route_table" "data" {
  for_each = aws_subnet.data
  vpc_id   = aws_vpc.this.id
  tags     = merge(local.common_tags, { Name = "${var.name}-rt-data-${replace(each.key, var.region, "")}" })
}

resource "aws_route_table_association" "data" {
  for_each       = aws_subnet.data
  subnet_id      = each.value.id
  route_table_id = aws_route_table.data[each.key].id
}

resource "aws_security_group" "alb" {
  name        = "${var.name}-sg-alb"
  description = "Public ALB: HTTP/HTTPS only from approved internet CIDRs"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.public_ingress_cidrs
    description = "HTTP from internet"
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.public_ingress_cidrs
    description = "HTTPS from internet"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Outbound response/application traffic"
  }

  tags = merge(local.common_tags, { Name = "${var.name}-sg-alb" })
}

resource "aws_security_group" "app" {
  name        = "${var.name}-sg-app"
  description = "Private application tier; accept only from ALB SG"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "App traffic from ALB"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    description = "Internal VPC egress"
  }

  tags = merge(local.common_tags, { Name = "${var.name}-sg-app" })
}

resource "aws_security_group" "endpoint" {
  name        = "${var.name}-sg-vpc-endpoints"
  description = "HTTPS access from private subnets to interface endpoints"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = concat(var.private_app_subnet_cidrs, var.private_data_subnet_cidrs)
    description = "HTTPS from private subnets"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    description = "Endpoint response traffic"
  }

  tags = merge(local.common_tags, { Name = "${var.name}-sg-endpoints" })
}

resource "aws_security_group" "data" {
  name        = "${var.name}-sg-data"
  description = "Private data tier; PostgreSQL access only from app SG"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
    description     = "PostgreSQL from app tier"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    description = "Internal VPC egress"
  }

  tags = merge(local.common_tags, { Name = "${var.name}-sg-data" })
}

resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = [for s in aws_subnet.public : s.id]

  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(local.common_tags, { Name = "${var.name}-nacl-public" })
}

resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = concat([for s in aws_subnet.app : s.id], [for s in aws_subnet.data : s.id])

  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 0
  }
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(local.common_tags, { Name = "${var.name}-nacl-private" })
}

resource "aws_vpc_endpoint" "s3" {
  count             = var.enable_s3_endpoint ? 1 : 0
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat([aws_route_table.public.id], [for r in aws_route_table.app : r.id], [for r in aws_route_table.data : r.id])
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
      Resource  = ["*"]
      Condition = { StringEquals = { "aws:SourceVpc" = aws_vpc.this.id } }
    }]
  })
  tags = merge(local.common_tags, { Name = "${var.name}-vpce-s3" })
}

resource "aws_vpc_endpoint" "sqs" {
  count               = var.enable_sqs_sns_endpoints ? 1 : 0
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.region}.sqs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [for s in aws_subnet.app : s.id]
  security_group_ids  = [aws_security_group.endpoint.id]
  tags = merge(local.common_tags, { Name = "${var.name}-vpce-sqs" })
}

resource "aws_vpc_endpoint" "sns" {
  count               = var.enable_sqs_sns_endpoints ? 1 : 0
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.region}.sns"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [for s in aws_subnet.app : s.id]
  security_group_ids  = [aws_security_group.endpoint.id]
  tags = merge(local.common_tags, { Name = "${var.name}-vpce-sns" })
}

resource "aws_s3_bucket" "flow_logs" {
  count  = var.enable_s3_flow_logs ? 1 : 0
  bucket = "${var.name}-${data.aws_caller_identity.current.account_id}-${var.region}-vpc-flow-logs"
  tags   = merge(local.common_tags, { Name = "${var.name}-vpc-flow-logs" })
}

resource "aws_s3_bucket_public_access_block" "flow_logs" {
  count                   = var.enable_s3_flow_logs ? 1 : 0
  bucket                  = aws_s3_bucket.flow_logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "flow_logs" {
  count  = var.enable_s3_flow_logs ? 1 : 0
  bucket = aws_s3_bucket.flow_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "flow_logs" {
  count  = var.enable_s3_flow_logs ? 1 : 0
  bucket = aws_s3_bucket.flow_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "flow_logs" {
  count  = var.enable_s3_flow_logs ? 1 : 0
  bucket = aws_s3_bucket.flow_logs[0].id
  policy = data.aws_iam_policy_document.flow_logs[0].json
}

resource "aws_flow_log" "this" {
  count                = var.enable_s3_flow_logs ? 1 : 0
  vpc_id               = aws_vpc.this.id
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "${aws_s3_bucket.flow_logs[0].arn}/vpc-flow-logs/"
  depends_on           = [aws_s3_bucket_policy.flow_logs]
  tags = merge(local.common_tags, { Name = "${var.name}-vpc-flow-log" })
}
