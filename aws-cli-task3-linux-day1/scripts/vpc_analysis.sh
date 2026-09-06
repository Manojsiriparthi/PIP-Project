#!/usr/bin/env bash
set -euo pipefail

REGION="${1:-ap-south-1}"

echo "=== VPCs ==="
aws ec2 describe-vpcs   --region "$REGION"   --query 'Vpcs[].{VpcId:VpcId,CIDR:CidrBlock,State:State,Default:IsDefault}'   --output table

echo "=== Subnets ==="
aws ec2 describe-subnets   --region "$REGION"   --query 'Subnets[].{SubnetId:SubnetId,VPC:VpcId,CIDR:CidrBlock,AZ:AvailabilityZone,AvailableIPs:AvailableIpAddressCount}'   --output table

echo "=== Route Tables ==="
aws ec2 describe-route-tables   --region "$REGION"   --query 'RouteTables[].{RouteTableId:RouteTableId,VPC:VpcId,Routes:Routes[].DestinationCidrBlock}'   --output json
