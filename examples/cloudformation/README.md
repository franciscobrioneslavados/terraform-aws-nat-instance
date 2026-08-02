# CloudFormation Example — NAT Instance

Deploys a NAT Instance equivalent to the Terraform module **v1.5.0**:
- Amazon Linux 2023 (x86_64, latest AMI via SSM parameter)
- **Access only via AWS Systems Manager** (no SSH, no key pair)
- IAM role + instance profile with `AmazonSSMManagedInstanceCore`
- No Elastic IP (public IP is dynamic)
- Route `0.0.0.0/0` from the private route table to the instance ENI

## Deploy

```bash
aws cloudformation create-stack \
  --stack-name nat-instance \
  --template-body file://nat-instance.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters \
    ParameterKey=VpcId,ParameterValue=vpc-xxxxxxxx \
    ParameterKey=PublicSubnetId,ParameterValue=subnet-xxxxxxxx \
    ParameterKey=PrivateSubnetCidr1,ParameterValue=10.0.1.0/24 \
    ParameterKey=PrivateSubnetCidr2,ParameterValue=10.0.2.0/24 \
    ParameterKey=RouteTableId,ParameterValue=rtb-xxxxxxxx \
    ParameterKey=ProjectName,ParameterValue=my-project \
    ParameterKey=Environment,ParameterValue=dev \
    ParameterKey=OwnerName,ParameterValue="Your Name"
```

Add `PrivateSubnetCidr3` only if you have a third private subnet. `PrivateSubnetCidr2`/`Cidr3` are optional.

`--capabilities CAPABILITY_NAMED_IAM` is required because the template creates an IAM role.

## Connect (no SSH)

```bash
aws ssm start-session --target <NatInstanceId>
```

`NatInstanceId` is in the stack outputs (`SsmConnectCommand` gives the ready-to-run command).

## Update / Delete

```bash
aws cloudformation update-stack --stack-name nat-instance --template-body file://nat-instance.yaml --capabilities CAPABILITY_NAMED_IAM
aws cloudformation delete-stack --stack-name nat-instance
```

> **Note:** CloudFormation will fail the `NatRoute` resource if the route table already has a `0.0.0.0/0` route. Remove the existing route (or use a route table without a default route) first.

## Parameters

| Name | Required | Description |
|------|----------|-------------|
| `VpcId` | yes | VPC where the NAT Instance will be deployed |
| `PublicSubnetId` | yes | Public subnet for the NAT Instance |
| `PrivateSubnetCidr1` | yes | CIDR of private subnet 1 (traffic source) |
| `PrivateSubnetCidr2` | no | Optional CIDR of private subnet 2 |
| `PrivateSubnetCidr3` | no | Optional CIDR of private subnet 3 |
| `RouteTableId` | yes | Private route table to update |
| `InstanceType` | no | Default `t3.micro` |
| `ProjectName` | yes | Tagging |
| `Environment` | yes | Tagging (dev, staging, prod) |
| `OwnerName` | yes | Tagging |
