resource "aws_iam_role" "ec2_full_access_role" {
  name = "ec2-full-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_vpc_s3_rds_full_access" {
  name        = "ec2-vpc-s3-rds-full-access"
  description = "Full access to EC2, VPC, S3, and RDS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ec2:*", "s3:*", "rds:*", "ssm:*"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ec2_full_access" {
  role       = aws_iam_role.ec2_full_access_role.name
  policy_arn = aws_iam_policy.ec2_vpc_s3_rds_full_access.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_full_access_role.name
}
