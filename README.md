# AWS NAT Instance Module

A Terraform module to deploy a **NAT Instance** in AWS VPC, configured to route outbound traffic from **private subnets** to the Internet.

## Features

- EC2 NAT Instance with Amazon Linux 2 (or custom AMI)
- Automatic iptables NAT configuration
- Elastic IP association
- Security Group with configurable SSH access
- Support for multiple Route Tables
- Optional existing key pair or auto-generated
- Terraform Registry compatible

## Architecture

```
                    Internet
                        |
                        v
                 +-------------+
                 |  IGW        |
                 +-------------+
                        |
          +-------------+-------------+
          |                           |
          v                           v
    +----------------+          +----------------+
    | Public Subnet  |          | Public Subnet  |
    | (AZ1)          |          | (AZ2)          |
    +----------------+          +----------------+
          |                           |
          v                           |
    +----------------+               |
    | NAT Instance   |<--------------+
    | (t3.micro)      |    (same instance in AZ1)
    +----------------+    routes for both AZs
          |
          v
    +----------------+
    | Private Subnet |
    | (AZ1 & AZ2)    |----> Internet via NAT Instance
    +----------------+
```

## Usage

### Basic Usage

```hcl
module "nat_instance" {
  source = "franciscobrioneslavados/nat-instance/aws"

  vpc_id               = "vpc-xxxxxxxxxxxxx"
  public_subnet_ids    = ["subnet-xxxxxxxxxxxxx"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  route_table_ids      = ["rtb-xxxxxxxxxxxxx"]

  project_name  = "my-project"
  environment   = "dev"
  owner_name    = "John Doe"
  instance_type = "t3.micro"
}
```

### With Multiple Route Tables

```hcl
module "nat_instance" {
  source = "franciscobrioneslavados/nat-instance/aws"

  vpc_id               = "vpc-xxxxxxxxxxxxx"
  public_subnet_ids    = ["subnet-xxxxxxxxxxxxx"]
  private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
  route_table_ids      = ["rtb-app-tier", "rtb-database-tier"]

  project_name  = "my-project"
  environment   = "prod"
  owner_name    = "John Doe"
  instance_type = "t3.micro"

  ssh_allowed_cidrs = ["your-ip/32"]
}
```

### With Existing Key Pair

```hcl
module "nat_instance" {
  source = "franciscobrioneslavados/nat-instance/aws"

  # ... other variables ...

  key_name = "my-existing-key"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5 |
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_id | VPC ID where the NAT Instance will be deployed | `string` | - | yes |
| public_subnet_ids | List of public subnet IDs (first one used) | `list(string)` | - | yes |
| private_subnet_cidrs | CIDR blocks of private subnets | `list(string)` | - | yes |
| route_table_ids | List of Route Table IDs for NAT routing | `list(string)` | - | yes |
| project_name | Project name for tagging | `string` | - | yes |
| environment | Environment name (dev, staging, prod) | `string` | - | yes |
| owner_name | Owner name for tagging | `string` | - | yes |
| instance_type | EC2 instance type | `string` | `t3.micro` | no |
| ssh_allowed_cidrs | CIDR blocks for SSH access (empty disables) | `list(string)` | `[]` | no |
| ami_id | Custom AMI ID (null = Amazon Linux 2) | `string` | `null` | no |
| key_name | Existing key pair name (null = auto-generate) | `string` | `null` | no |
| managed_by | ManagedBy tag value | `string` | `Terraform` | no |

## Outputs

| Name | Description |
|------|-------------|
| nat_instance_id | ID of the NAT Instance |
| nat_instance_arn | ARN of the NAT Instance |
| nat_instance_public_ip | Public IP (EIP) of the NAT Instance |
| nat_instance_private_ip | Private IP of the NAT Instance |
| nat_network_interface_id | Primary network interface ID |
| nat_security_group_id | Security Group ID |
| key_pair_name | Key pair name used |
| private_key_file | Local path to private key (if auto-generated) |
| ssh_command | SSH command to connect to NAT Instance |
| chmod_command | Command to set key permissions |

## Testing / Validation

1. Connect to the NAT Instance:
   ```bash
   ssh -i your-key.pem ec2-user@<NAT_PUBLIC_IP>
   ```

2. Verify IP forwarding:
   ```bash
   sudo sysctl net.ipv4.ip_forward
   ```

3. Verify NAT rules:
   ```bash
   sudo iptables -t nat -L -n -v
   ```

4. Test Internet connectivity from NAT:
   ```bash
   curl -s https://ifconfig.me
   ping -c 3 8.8.8.8
   ```

5. Test from a private instance:
   ```bash
   # From NAT Instance, SSH to private instance
   ssh ec2-user@<PRIVATE_IP>
   
   # From private instance
   curl -s https://ifconfig.me  # Should show NAT's EIP
   ```

## Notes

- The NAT Instance must have **source_dest_check = false** (handled automatically)
- The EIP is associated to the ENI to avoid recreation
- Private subnets must use route **0.0.0.0/0** pointing to the NAT Instance
- This module does not create the Internet Gateway or public Route Tables
- For high availability, consider deploying NAT Instances in multiple AZs

## References

- [Terraform aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
- [Terraform aws_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route)
- [AWS NAT Instance](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_NAT_Instance.html)

## License

MIT License - see [LICENSE](LICENSE) for details.
