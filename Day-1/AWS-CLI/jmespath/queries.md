# JMESPath Queries

## EC2 by tag

```bash
aws ec2 describe-instances \
  --query "Reservations[].Instances[?Tags[?Key=='Environment' && Value=='Dev']].{ID:InstanceId,Type:InstanceType,State:State.Name}" \
  --output table
```

## Running EC2

```bash
aws ec2 describe-instances \
  --query "Reservations[].Instances[?State.Name=='running'].{ID:InstanceId,Type:InstanceType,AZ:Placement.AvailabilityZone}" \
  --output table
```

## RDS

```bash
aws rds describe-db-instances \
  --region ap-south-1 \
  --query "DBInstances[].{DB:DBInstanceIdentifier,Engine:Engine,Class:DBInstanceClass,Status:DBInstanceStatus}" \
  --output table
```

## S3 buckets

```bash
aws s3api list-buckets --query "Buckets[].Name" --output table
```

## VPC

```bash
aws ec2 describe-vpcs \
  --query "Vpcs[].{ID:VpcId,CIDR:CidrBlock,State:State,Default:IsDefault}" \
  --output table
```

## Security groups with publicly open SSH

```bash
aws ec2 describe-security-groups \
  --query "SecurityGroups[?IpPermissions[?FromPort==`22` && IpRanges[?CidrIp=='0.0.0.0/0']]].{ID:GroupId,Name:GroupName}" \
  --output table
```

Use this as an audit query. Do not intentionally expose SSH to the internet in production.
