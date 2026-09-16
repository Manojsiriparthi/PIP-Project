# infra-vpc — Day 2 VPC Assignment

This package is a complete Terraform VPC implementation for the PIP assignment. It is intentionally structured as **reusable module + independent dev/prod roots**, rather than putting everything into one root directory.

## Assignment coverage — 7 points

1. **VPC + CIDR + subnet allocation** — /16 VPC, three public, three private application, and three private data subnets across three Availability Zones.
2. **Internet/NAT + route tables + traffic flow** — Internet Gateway, NAT Gateway(s), dedicated public/app/data route tables, and explicit route-table associations.
3. **Security Groups + NACLs** — ALB/app/data/endpoint SGs with least-privilege paths; subnet-level NACL guardrails; no SSH/RDP from `0.0.0.0/0`.
4. **VPC endpoints** — S3 Gateway endpoint plus private SQS and SNS Interface endpoints. S3 gateway endpoints do not use a security group; SQS/SNS interface endpoints use the endpoint SG.
5. **VPC Flow Logs to S3** — encrypted, private, versioned S3 bucket with a delivery policy and VPC Flow Log capturing `ALL` traffic.
6. **Dev/Prod + remote state + native locking** — separate `envs/dev` and `envs/prod` roots, each with `backend.tf`, `outputs.tf`, `terraform.tfvars`, and `.terraform.lock.hcl`; S3 backend uses Terraform's native `use_lockfile = true` locking.
7. **Reusable Terraform design** — all AWS resources live in `module/`; environment roots pass variables and expose outputs. Documentation covers design, CIDRs, traffic, security, endpoints, logs, and deployment.

## Architecture

```text
                         INTERNET
                             |
                      +------+------+
                      |     IGW     |
                      +------+------+
                             |
              +--------------+--------------+
              |                             |
       PUBLIC SUBNETS (3 AZs)        S3 Gateway Endpoint
       ALB / NAT Gateway             (route-table based)
              |                             |
       +------+-------+                     |
       | Public RT    |---------------------+
       +------+-------+
              |
         NAT Gateway
              |
       +------+------------------------------+
       |                                     |
 PRIVATE APP SUBNETS (3 AZs)          PRIVATE DATA SUBNETS (3 AZs)
 EC2 / ECS / Lambda ENIs              RDS / databases
       |                                     |
       | 8080 from ALB SG                   | 5432 from App SG
       +------------------+------------------+
                          |
              VPC Endpoint SG (HTTPS/443)
                     /             \
                  SQS              SNS
             Interface EP      Interface EP

 VPC Flow Logs (ALL traffic) ---> private S3 log bucket

 Security layers:
   Internet SG rules -> workload SG rules -> subnet NACLs -> IAM/resource policies
```

## Important security design

- `0.0.0.0/0` is used only where an internet-facing path is intentional: public HTTP/HTTPS ingress and public/NAT routing. It is **not** used for SSH/RDP access.
- Security Groups are stateful and are the main workload access control.
- NACLs are stateless subnet-level guardrails, so return/ephemeral traffic must be considered.
- Private app and data subnets have no direct route to the Internet Gateway.
- S3 is reached through the S3 Gateway Endpoint instead of requiring NAT for normal S3 traffic.
- SQS and SNS use Interface Endpoints so application workloads can reach those AWS services privately over HTTPS.
- Flow logs are stored in an encrypted, versioned, public-access-blocked S3 bucket.

## Cost note

The dev environment defaults to **one NAT Gateway** to reduce lab cost. Prod defaults to **one NAT Gateway per AZ** for higher availability. NAT Gateways, interface endpoints, and other AWS resources can incur charges. Run `terraform plan` and review costs before `apply`.

## State backend

Each environment contains `backend.tf`. Replace `REPLACE_WITH_PIP_TERRAFORM_STATE_BUCKET` with an existing S3 state bucket before running `terraform init`. Native S3 state locking is enabled with `use_lockfile = true`; DynamoDB locking is not required for this design.

The backend bucket should have versioning, encryption, and public-access blocking enabled.

## Directory

```text
infra-vpc/
├── module/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── envs/
│   ├── dev/
│   │   ├── backend.tf
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars
│   │   └── .terraform.lock.hcl
│   └── prod/
│       ├── backend.tf
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── terraform.tfvars
│       └── .terraform.lock.hcl
├── docs/
│   ├── design.md
│   ├── cidr-subnet-allocation.md
│   └── assignment-7-points.md
└── scripts/
    └── create-state-bucket.sh
```

## Quick start

```bash
cd infra-vpc/envs/dev
# edit backend.tf and set the real state bucket name
terraform init
terraform fmt -recursive
terraform validate
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Destroy only when you intentionally want to remove the lab infrastructure:

```bash
terraform destroy -var-file=terraform.tfvars
```
