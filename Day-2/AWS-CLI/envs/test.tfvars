environment = "test"
name_prefix = "pip-day2-test"
project_tag = "PIP"
owner_email = "siriparthi.manojkumar@gmail.com"
cloudwatch_namespace = "PIP/EC2Benchmark"

instances_by_region = {
  "ap-south-1" = {
    "01-t4g" = {
      instance_type = "t4g.micro"
      architecture  = "arm64"
      name          = "pip-test-ap-south-1-t4g"
    }
    "02-t3" = {
      instance_type = "t3.micro"
      architecture  = "x86_64"
      name          = "pip-test-ap-south-1-t3"
    }
  }
  "us-east-1" = {
    "03-m6i" = {
      instance_type = "m6i.large"
      architecture  = "x86_64"
      name          = "pip-test-us-east-1-m6i"
    }
    "04-c6i" = {
      instance_type = "c6i.large"
      architecture  = "x86_64"
      name          = "pip-test-us-east-1-c6i"
    }
  }
  "eu-west-1" = {
    "05-r6i" = {
      instance_type = "r6i.large"
      architecture  = "x86_64"
      name          = "pip-test-eu-west-1-r6i"
    }
    "06-t4g" = {
      instance_type = "t4g.micro"
      architecture  = "arm64"
      name          = "pip-test-eu-west-1-t4g"
    }
  }
  "ap-southeast-1" = {
    "07-t3" = {
      instance_type = "t3.micro"
      architecture  = "x86_64"
      name          = "pip-test-ap-southeast-1-t3"
    }
    "08-m6i" = {
      instance_type = "m6i.large"
      architecture  = "x86_64"
      name          = "pip-test-ap-southeast-1-m6i"
    }
  }
}
