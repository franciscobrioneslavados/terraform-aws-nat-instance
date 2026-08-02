# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.5.0] - 2026-08-01

### Added
- Secure access via AWS Systems Manager: new IAM role + instance profile with `AmazonSSMManagedInstanceCore` attached to the NAT Instance.
- `amazon-ssm-agent` installed and activated in `user_data` for all supported OS types (AL2/al2023 via `yum`, Ubuntu via `snap`).
- New output `ssm_connect_command` with a ready-to-run `aws ssm start-session` command.
- README section documenting SSM connection and `aws ssm send-command`.

### Removed
- Elastic IP (`aws_eip`) and EIP association. The public IP is now dynamic; NAT routing is unaffected because the route points to the instance ENI/private IP.

### Changed
- `nat_instance_public_ip` output now returns the instance's dynamic public IP instead of the EIP.
- README: SSH disabled by default (`ssh_allowed_cidrs = []`), SSM documented as the recommended access method.

## [1.4.0] - 2026-05-28

### Added
- Multi-architecture support: added `cpu_architecture` variable to select between `x86_64` and `arm64` (Graviton) AMIs.
- Amazon Linux 2023 support: added `al2023` to `os_type` to allow deploying using the latest AWS standard OS.
- Inbound ICMP rule: added support for incoming ICMP traffic from private subnets in the Security Group to enable diagnostics (ping) and PMTUD.
- Dynamic network interface detection: updated `user_data` scripts to dynamically detect the default gateway interface, preventing silent routing failures on modern Nitro/Graviton instances.
- AWS Console Deployment manual guide in README.md.

### Fixed
- Fixed AMI indexing in `aws_instance` using `coalesce` and `one()` to prevent potential *index out of bounds* planning errors when providing custom AMI IDs.

## [1.3.0] - 2026-04-13

### Added
- Multi-OS support: Choose between Amazon Linux 2 and Ubuntu 20.04 using `os_type` variable.
- Automatic AMI detection for both supported OS types.
- Specialized `user_data` scripts for Ubuntu (using `apt` and `netfilter-persistent`) and AL2 (using `yum` and `iptables-services`).

### Fixed
- Improved heredoc syntax in `variables.tf` to avoid unterminated string errors.
- Consolidated duplicate `user_data` attributes in `aws_instance` resource.

## [1.1.0] - 2026-03-28

### Added
- Support for multiple Route Tables (`route_table_ids` as list)
- Custom AMI support (`ami_id` variable)
- Existing key pair support (`key_name` variable)
- Conditional SSH ingress (empty list disables SSH)
- Amazon Linux 2023 compatibility (using `dnf` instead of `yum`)
- GitHub Actions CI workflow
- Example configurations (`examples/basic` and `examples/multi-rt`)
- Additional outputs: `nat_instance_id`, `nat_instance_arn`, `key_pair_name`

### Changed
- Renamed EIP resource from `eip_nat` to `nat` for consistency
- Renamed Route resource from `private_nat_instance` to `nat_instance` for consistency
- Updated README with complete inputs/outputs documentation

### Removed
- Provider configuration from module (should be in root module)

## [1.0.0] - 2026-03-28

### Added
- Initial NAT Instance module
- Amazon Linux 2 AMI
- Automatic iptables NAT configuration
- Elastic IP association
- Security Group with SSH access
- Single Route Table support
- Auto-generated key pair
- Basic documentation
