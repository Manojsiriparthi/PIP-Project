# VPC Design — What We Created, Why We Created It, and How Traffic Flows

## 1. VPC

The VPC is the isolated network boundary. DNS support and DNS hostnames are enabled so AWS service names and private endpoint DNS names work correctly.

## 2. Public vs private subnets

### Public
Public subnets have a route to the Internet Gateway. They are intended for internet-facing components such as an ALB and NAT Gateways. Instances should only receive public IPs when that exposure is explicitly required.

### Private application
Private application subnets have no Internet Gateway route. Their default route can point to a NAT Gateway for controlled outbound internet access. They are suitable for EC2/ECS application workloads.

### Private data
Private data subnets have no direct internet route. They are intended for RDS/database/cache resources and are protected by data-tier security groups.

## 3. Route tables

There is one public route table shared by public subnets. It has `0.0.0.0/0 -> Internet Gateway`.

Each application subnet has its own route table so each AZ can use the local NAT Gateway in production. In dev, `single_nat_gateway=true` allows the three app route tables to share one NAT Gateway to reduce cost.

Each data subnet has its own route table with only the implicit `local` VPC route. This intentionally prevents direct internet access.

The S3 Gateway Endpoint is associated with the route tables. AWS adds an endpoint route for S3 so private workloads can reach S3 without traversing a NAT Gateway or Internet Gateway.

## 4. Security Groups

### ALB SG
`0.0.0.0/0` is allowed only for TCP 80 and 443 because these are public web entry points. SSH and RDP are not exposed.

### App SG
The application tier accepts TCP 8080 only from the ALB security group. This is better than opening 8080 to an internet CIDR because the source is an AWS identity/security group rather than a broad address range.

### Data SG
The data tier accepts PostgreSQL 5432 only from the application security group.

### Endpoint SG
The SQS/SNS interface endpoint network interfaces accept HTTPS 443 only from the private app/data subnet CIDRs.

### S3 note
The S3 Gateway Endpoint does **not** have a security group because it is a route-table-based gateway endpoint. The workload security group controls the instance's egress, while the endpoint policy and S3 bucket policy provide additional authorization controls.

## 5. NACLs

NACLs operate at subnet level and are stateless. The public NACL allows web traffic and ephemeral return traffic from the internet, with outbound traffic allowed. The private NACL allows VPC traffic and ephemeral return traffic required for NAT-based connections.

Security Groups remain the primary workload-level control; NACLs provide a second subnet boundary.

## 6. VPC endpoints

### S3 Gateway Endpoint
Private workloads can access S3 without using NAT for normal in-Region S3 traffic. This can reduce NAT dependency and cost.

### SQS/SNS Interface Endpoints
SQS and SNS endpoints use AWS PrivateLink interface endpoints with private DNS and the endpoint security group. Application traffic stays on the AWS private network rather than requiring a public service endpoint path.

## 7. VPC Flow Logs to S3

The VPC Flow Log captures `ALL` traffic metadata and delivers log objects to a dedicated S3 bucket. The bucket is private, versioned, encrypted with SSE-S3, and protected by public-access-block settings.

### How to use the logs
1. Open the flow-log S3 bucket.
2. Browse the `vpc-flow-logs/` prefix and AWS log-delivery objects.
3. Download/query the records with Athena, Glue, or another log-processing pipeline.
4. Investigate rejected/accepted traffic, source/destination IPs, ports, protocols, and time windows.
5. Use findings to tighten SG/NACL rules or troubleshoot connectivity.

Flow Logs are metadata about network traffic; they are not packet captures and do not contain application payloads.

## 8. Traffic examples

### Internet -> public ALB -> private app
`Client -> IGW -> public subnet/ALB -> app SG -> private app subnet`

### Private app -> internet
`App -> app route table -> NAT Gateway in public subnet -> IGW -> Internet`

### Private app -> S3
`App -> S3 gateway endpoint route -> S3`

### Private app -> SQS/SNS
`App -> private DNS -> interface endpoint ENI -> SQS/SNS`

### App -> database
`App -> data SG -> private data subnet -> database`

## 9. Why this design

The design separates exposure, application workloads, and data workloads. Routing, SGs, NACLs, endpoints, and flow logs each solve a different networking/security problem, making the VPC easier to troubleshoot and safer to evolve.
