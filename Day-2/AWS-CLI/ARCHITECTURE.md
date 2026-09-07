# Architecture

```text
                        Terraform Root
                             |
              +--------------+--------------+
              |              |              |
        AWS provider    AWS provider    AWS provider ...
          aliases
              |
   +----------+----------+----------+----------+
   |                     |                     |
ap-south-1            us-east-1             eu-west-1 ... ap-southeast-1
   |                     |                     |
 2 EC2                  2 EC2                  2 EC2 ... 2 EC2
   |                     |                     |
   +---------------------+---------------------+
                         |
              EC2 Instance Profile
                         |
                Least-Privilege Role
                 /                 \
        ec2:DescribeTags    cloudwatch:PutMetricData
```

T4g instances use ARM64 AMIs; the other selected families use x86_64 AMIs.
