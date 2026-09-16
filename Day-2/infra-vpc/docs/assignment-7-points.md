# Assignment — 7 Point Mapping

## 1. VPC, CIDR and subnet architecture

Created a `/16` VPC with public, private application, and private data subnets across three AZs. CIDRs are separated by environment and tier.

## 2. Routing and internet/NAT connectivity

Created an Internet Gateway, public route table, per-AZ application route tables, NAT Gateway(s), and isolated data route tables. Traffic paths are documented.

## 3. Security Groups and NACLs

Created dedicated ALB, application, data, and endpoint security groups. Public `0.0.0.0/0` access is limited to intentional web ports. NACLs provide subnet-level stateless guardrails and account for ephemeral return traffic.

## 4. VPC Endpoints

Created an S3 Gateway Endpoint and private Interface Endpoints for SQS and SNS. Endpoint SG rules restrict HTTPS access from private subnets.

## 5. VPC Flow Logs to S3

Created a dedicated private S3 bucket with versioning, encryption, public-access blocking, and a delivery bucket policy. VPC Flow Logs capture all traffic metadata for troubleshooting and security analysis.

## 6. Dev/Prod separation and Terraform state locking

Dev and prod are independent Terraform roots. Each root has `backend.tf`, `outputs.tf`, `terraform.tfvars`, variables, and `.terraform.lock.hcl`. The S3 backend uses Terraform native S3 lock files with `use_lockfile = true`.

## 7. Reusable module and documentation

All infrastructure resources are implemented in `module/`, while dev/prod only provide environment inputs and outputs. `design.md` explains what was created, why it exists, and how it is used. `cidr-subnet-allocation.md` explains CIDRs, public/private traffic, route tables, and the purpose of `0.0.0.0/0`.
