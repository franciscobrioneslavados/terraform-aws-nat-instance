# AWS NAT Instance Module

A Terraform module to deploy a **NAT Instance** in AWS VPC, configured to route outbound traffic from **private subnets** to the Internet.

## Features

- EC2 NAT Instance with Amazon Linux 2, Amazon Linux 2023 or Ubuntu (or custom AMI)
- Automatic iptables NAT configuration
- Security Group restricted to private subnet traffic
- **Secure access via AWS Systems Manager (Session Manager)**
- **IAM instance profile with `AmazonSSMManagedInstanceCore`**
- Support for multiple Route Tables
- Multi-architecture support (x86_64 and arm64/Graviton)
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
| ami_id | Custom AMI ID (null = auto-detect) | `string` | `null` | no |
| os_type | OS type: `amazon-linux-2`, `al2023` or `ubuntu` | `string` | `amazon-linux-2` | no |
| cpu_architecture | `x86_64` or `arm64` (must match instance_type) | `string` | `x86_64` | no |
| managed_by | ManagedBy tag value | `string` | `Terraform` | no |

## Outputs

| Name | Description |
|------|-------------|
| nat_instance_id | ID of the NAT Instance |
| nat_instance_arn | ARN of the NAT Instance |
| nat_instance_public_ip | Public IP of the NAT Instance (dynamic) |
| nat_instance_private_ip | Private IP of the NAT Instance |
| nat_network_interface_id | Primary network interface ID |
| nat_security_group_id | Security Group ID |
| ssm_connect_command | Ready-to-run SSM connection command |

## Secure access via AWS Systems Manager (Session Manager)

The module attaches an **IAM instance profile** with `AmazonSSMManagedInstanceCore`, so you can connect to the instance **without opening any inbound ports**.

### Local prerequisites

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [session-manager-plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)
- Credentials with permission to start SSM sessions on the instance

### Connect (shell)

```bash
aws ssm start-session --target <NAT_INSTANCE_ID>
```

Use the `nat_instance_id` output, or copy the ready command from the `ssm_connect_command` output.

### Run remote commands (non-interactive)

```bash
aws ssm send-command \
  --instance-ids <NAT_INSTANCE_ID> \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["sudo iptables -t nat -L -n -v"]'
```

### SSM notes

- The agent opens an **outbound** connection to SSM endpoints; no inbound 443 is required (egress already allows it).
- `amazon-ssm-agent` is installed/activated by `user_data` for all OS types.

## Testing / Validation

1. Connect to the NAT Instance via SSM:
   ```bash
   aws ssm start-session --target <NAT_INSTANCE_ID>
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
   # From the private instance (connect to it via Session Manager if it has the agent)
   curl -s https://ifconfig.me  # Should show the NAT's public IP
   ```

## AWS Console Deployment (Manual Step-by-Step)

If you need to deploy and configure this NAT Instance manually using the **AWS Web Console** instead of Terraform, follow these steps:

### 1. Launch the EC2 Instance (NAT)
1. Navigate to the **EC2 Dashboard** and click **Launch instance**.
2. **Name & Tags:** Enter a name (e.g., `my-nat-instance`).
3. **Application and OS Image:** Choose **Amazon Linux 2023** (or Amazon Linux 2 / Ubuntu).
4. **Instance Type:** Select a cost-effective type, such as `t4g.nano` or `t3.micro`.
5. **Login credentials:** Choose *Proceed without a key pair* — access is via SSM.
6. **Network Settings:**
   - Click **Edit**.
   - **VPC:** Select your target VPC.
   - **Subnet:** Select a **Public Subnet** (with an active Internet Gateway route).
   - **Auto-assign public IP:** Select **Enable**.
   - **Firewall (Security Groups):** Create a new Security Group with these rules:
     - **Inbound Rule 1:** All TCP (Ports 0 - 65535) allowed from your **Private Subnet CIDRs** (e.g., `10.0.1.0/24`).
     - **Inbound Rule 2:** All UDP (Ports 0 - 65535) allowed from your **Private Subnet CIDRs**.
     - **Inbound Rule 3:** ICMP (All) allowed from your **Private Subnet CIDRs** (essential for pinging and PMTUD).
     - **Outbound Rule:** Allow All Traffic (`0.0.0.0/0`).
7. Click **Launch instance**.

### 2. Disable Source/Destination Check
*By default, EC2 instances drop traffic that is not destined for their own IP. We must disable this check to allow routing.*
1. Go to the **EC2 Instances** list.
2. Select your new NAT Instance.
3. Click **Actions** > **Networking** > **Change source/destination check**.
4. Select **Stop** (which disables the check) and save.

### 3. Attach an IAM role for SSM access
*Recommended: lets you connect via AWS Systems Manager (Session Manager).*
1. Go to **IAM** > **Roles** > **Create role**.
2. Trusted entity: **AWS service** > **EC2**.
3. Add the **AmazonSSMManagedInstanceCore** managed policy.
4. Name it (e.g., `ssm-nat-instance`) and create it.
5. Back in EC2, select the instance > **Actions** > **Security** > **Modify IAM role**, and attach the new role.

### 4. Configure IP Forwarding & NAT Masquerading
1. Connect to your instance via **Session Manager**:
   ```bash
   aws ssm start-session --target <NAT_INSTANCE_ID>
   ```
   *(The agent is installed by `user_data`; wait a couple of minutes after launch if the session fails.)*
2. Enable IPv4 forwarding in the Linux Kernel:
   ```bash
   echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
   sudo sysctl -p
   ```
3. Install and enable the `iptables` persistence service:
   ```bash
   sudo yum install -y iptables-services
   sudo systemctl enable iptables
   sudo systemctl start iptables
   ```
4. Set up the NAT masquerading rule (this dynamically detects your primary network interface, such as `eth0` or `ens5`):
   ```bash
   PRIMARY_IFACE=$(ip route show | grep '^default' | awk '{print $5}')
   sudo iptables -t nat -A POSTROUTING -o $PRIMARY_IFACE -j MASQUERADE
   sudo iptables -A FORWARD -i $PRIMARY_IFACE -o $PRIMARY_IFACE -j ACCEPT
   sudo service iptables save
   ```

### 5. Update the Route Table for Private Subnets
1. Go to the **VPC Dashboard** > **Route Tables**.
2. Select the Route Table associated with your **Private Subnets**.
3. Click the **Routes** tab, then **Edit routes**.
4. Click **Add route**:
   - **Destination:** `0.0.0.0/0`
   - **Target:** Select **Instance**, then choose your **NAT Instance**.
5. Click **Save changes**. Your private subnet instances now have secure internet access!

## Notes

- The NAT Instance must have **source_dest_check = false** (handled automatically)
- The public IP is **dynamic** and changes if the instance restarts; outbound traffic is unaffected because the route points to the instance ENI/private IP
- Private subnets must use route **0.0.0.0/0** pointing to the NAT Instance
- This module does not create the Internet Gateway or public Route Tables
- For high availability, consider deploying NAT Instances in multiple AZs

## Versioning

This module uses [GitHub Releases](https://github.com/franciscobrioneslavados/terraform-aws-nat-instance/releases) for versioning.

### Using a Specific Version

```hcl
module "nat_instance" {
  source = "git::https://github.com/franciscobrioneslavados/terraform-aws-nat-instance.git//.?ref=v1.2.2"

  # ... variables
}
```

### Using Latest (main branch)

```hcl
module "nat_instance" {
  source = "git::https://github.com/franciscobrioneslavados/terraform-aws-nat-instance.git//.?ref=main"

  # ... variables
}
```

**Note**: Using `main` branch may include breaking changes. Recommended for development only.

## References

- [Terraform aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
- [Terraform aws_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route)
- [AWS NAT Instance](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_NAT_Instance.html)

## License

MIT License - see [LICENSE](LICENSE) for details.
