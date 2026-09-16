# CIDR and Subnet Allocation

## Dev

| Layer | AZ-a | AZ-b | AZ-c |
|---|---|---|---|
| VPC | `10.10.0.0/16` | same VPC | same VPC |
| Public | `10.10.0.0/24` | `10.10.1.0/24` | `10.10.2.0/24` |
| Private App | `10.10.10.0/24` | `10.10.11.0/24` | `10.10.12.0/24` |
| Private Data | `10.10.20.0/24` | `10.10.21.0/24` | `10.10.22.0/24` |

## Prod

| Layer | AZ-a | AZ-b | AZ-c |
|---|---|---|---|
| VPC | `10.30.0.0/16` | same VPC | same VPC |
| Public | `10.30.0.0/24` | `10.30.1.0/24` | `10.30.2.0/24` |
| Private App | `10.30.10.0/24` | `10.30.11.0/24` | `10.30.12.0/24` |
| Private Data | `10.30.20.0/24` | `10.30.21.0/24` | `10.30.22.0/24` |

## Why `/16` for the VPC?

A `/16` provides 65,536 IPv4 addresses before AWS subnet reservations. It gives room for future subnets, additional AZs, and growth without redesigning the VPC CIDR.

## Why `/24` subnets?

A `/24` contains 256 addresses before AWS subnet reservations. It is easy to reason about and provides enough capacity for a small PIP lab or starter application tier.

## Why separate ranges for app and data?

Separate CIDR ranges make the architecture clear and allow different route tables, NACLs, security policies, and future network controls to be applied to application and data workloads.

## Public subnet traffic

Public route table:

```text
10.x.0.0/16 -> local
0.0.0.0/0   -> Internet Gateway
```

A resource in a public subnet can reach the internet when it has a public IPv4 address and its security controls permit the traffic.

## Private app subnet traffic

Typical route table:

```text
10.x.0.0/16 -> local
0.0.0.0/0   -> NAT Gateway
S3 prefix   -> S3 Gateway Endpoint
```

This allows outbound internet access through NAT without allowing unsolicited inbound internet connections to the private workload.

## Private data subnet traffic

Typical route table:

```text
10.x.0.0/16 -> local
```

No default internet route is configured. The database tier therefore remains private.

## `0.0.0.0/0` meaning and security purpose

`0.0.0.0/0` means all IPv4 destinations. It is not automatically unsafe; its security depends on where it is used and which port/protocol is allowed.

- Public route table: `0.0.0.0/0 -> IGW` means internet connectivity for the public subnet.
- NAT route: `0.0.0.0/0 -> NAT Gateway` means private workloads can initiate outbound connections.
- ALB SG: `0.0.0.0/0` is restricted to 80/443 because the web endpoint is intentionally public.
- SSH/RDP: not opened to `0.0.0.0/0`; use SSM or a controlled administrative path.

## Route-table allocation summary

| Route table | Associated subnets | Default route | Purpose |
|---|---|---|---|
| Public RT | 3 public | `0.0.0.0/0 -> IGW` | Internet-facing tier / NAT |
| App RT x3 | 3 private app | `0.0.0.0/0 -> NAT` | Controlled outbound access |
| Data RT x3 | 3 private data | none | Isolated data tier |
| S3 endpoint route | Public/App/Data RTs | S3 prefix -> endpoint | Private S3 access |
