#!/usr/bin/env bash
set -euo pipefail

REGION="${1:-ap-south-1}"

aws ec2 describe-instances   --region "$REGION"   --query 'Reservations[].Instances[].{InstanceId:InstanceId,Type:InstanceType,State:State.Name,AZ:Placement.AvailabilityZone,PrivateIP:PrivateIpAddress,PublicIP:PublicIpAddress}'   --output table
