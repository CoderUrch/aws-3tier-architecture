# AWS 3-Tier Architecture with Terraform

A complete 3-tier web application infrastructure deployed on AWS using Terraform, featuring high availability, auto-scaling, and proper security isolation.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Tier      │    │   App Tier      │    │   Database      │
│                 │    │                 │    │                 │
│ • React App     │    │ • Node.js API   │    │ • Aurora MySQL  │
│ • Nginx         │    │ • Business Logic│    │ • Multi-AZ      │
│ • Public Subnet │    │ • Private Subnet│    │ • Private Subnet│
│ • Auto Scaling  │    │ • Auto Scaling  │    │ • Managed       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Internet-facing │    │ Internal Load   │    │ Security Groups │
│ Load Balancer   │    │ Balancer        │    │ Port 3306 only  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Features

- **High Availability**: Multi-AZ deployment across 2 availability zones
- **Auto Scaling**: Automatic scaling based on demand for web and app tiers
- **Security**: Proper network isolation with security groups and private subnets
- **Load Balancing**: Application Load Balancers for both web and app tiers
- **Database**: Aurora MySQL cluster with read replicas
- **Storage**: S3 bucket for application code storage
- **Infrastructure as Code**: Complete Terraform configuration

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- SSH key pair named `demo` in your AWS account
- Terraform Cloud account (optional, for remote state)

## Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/CoderUrch/aws-3tier-architecture.git
   cd aws-3tier-architecture
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Review and modify variables**
   ```bash
   # Edit variables.tf if needed
   # Update backend.tf for your Terraform Cloud workspace
   ```

4. **Deploy the infrastructure**
   ```bash
   terraform plan
   terraform apply
   ```

5. **Access your infrastructure**
   ```bash
   # Get the application URL
   terraform output application_url
   ```

## Infrastructure Components

### Networking
- **VPC**: `10.0.0.0/16` with DNS support enabled
- **Public Subnets**: `10.0.1.0/24`, `10.0.2.0/24` (Web tier)
- **Private Subnets**: `10.0.3.0/24`, `10.0.4.0/24` (App tier)
- **Database Subnets**: `10.0.5.0/24`, `10.0.6.0/24` (Database tier)
- **NAT Gateways**: 2 NAT gateways for high availability
- **Internet Gateway**: For public internet access

### Compute
- **Web Tier**: Auto Scaling Group with 2-3 t3.micro instances
- **App Tier**: Auto Scaling Group with 2-3 t3.micro instances
- **Launch Templates**: Configured with proper IAM roles and security groups

### Database
- **Aurora MySQL**: Multi-AZ cluster with 2 instances
- **Instance Class**: db.t3.medium
- **Backup**: 7-day retention period
- **Security**: Accessible only from app tier

### Load Balancers
- **Internet-facing ALB**: Routes traffic to web tier
- **Internal ALB**: Routes traffic from web to app tier
- **Health Checks**: Configured for both tiers

### Security
- **Security Groups**: Least privilege access between tiers
- **IAM Roles**: EC2 instances with S3 and RDS access
- **Network ACLs**: Default VPC security

## Outputs

After deployment, Terraform provides these key outputs:

- `application_url`: Public URL to access your application
- `aurora_cluster_endpoint`: Database writer endpoint
- `aurora_cluster_reader_endpoint`: Database reader endpoint
- `s3_bucket_name`: S3 bucket for application code
- `vpc_id`: VPC identifier
- `public_subnet_ids`: Web tier subnet IDs
- `private_subnet_ids`: App tier subnet IDs

## Manual Application Setup

The infrastructure is deployed without application code. To set up the applications manually:

### Web Tier Setup
1. SSH to web tier instances via public IP
2. Install Node.js, npm, and nginx
3. Download React app from S3: `aws s3 cp s3://your-bucket/web-tier/ . --recursive`
4. Build and configure the application

### App Tier Setup
1. SSH to app tier instances via web tier bastion
2. Install Node.js and npm
3. Download Node.js API from S3: `aws s3 cp s3://your-bucket/app-tier/ . --recursive`
4. Configure database connection and start the API

### Database Setup
1. Connect to Aurora cluster from app tier
2. Create required database schema
3. Set up initial data if needed

## SSH Access

**Web Tier (Direct)**:
```bash
ssh -i demo.pem ec2-user@<web-tier-public-ip>
```

**App Tier (Via Bastion)**:
```bash
ssh -i demo.pem -J ec2-user@<web-tier-public-ip> ec2-user@<app-tier-private-ip>
```

## Cost Optimization

- **Instance Types**: Using t3.micro for cost efficiency
- **Auto Scaling**: Scales down during low usage
- **Aurora**: Serverless option available for variable workloads
- **NAT Gateway**: Consider NAT instances for lower cost in dev environments

## Security Considerations

- Web tier allows HTTP (80) and SSH (22) from your IP only
- App tier allows port 4000 from web tier and your IP only
- Database allows port 3306 from app tier only
- All outbound traffic allowed for updates and dependencies

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

**Note**: Ensure you backup any important data before destroying resources.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For issues and questions:
- Create an issue in this repository
- Check AWS documentation for service-specific questions
- Review Terraform documentation for configuration issues