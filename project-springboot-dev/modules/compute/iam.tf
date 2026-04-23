############################
# SpringBoot ASG용 IAM
############################
resource "aws_iam_role" "springboot" {
  name = "${var.project_name}-springboot-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-springboot-role"
  })
}

resource "aws_iam_role_policy_attachment" "springboot_cloudwatch" {
  role       = aws_iam_role.springboot.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "springboot" {
  name = "${var.project_name}-springboot-profile"
  role = aws_iam_role.springboot.name

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-springboot-profile"
  })
}

############################
# Jenkins용 IAM (DR 제어 권한)
############################
resource "aws_iam_role" "jenkins" {
  name = "${var.project_name}-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-jenkins-role"
  })
}

resource "aws_iam_role_policy" "jenkins_dr_control" {
  name = "${var.project_name}-jenkins-dr-control"
  role = aws_iam_role.jenkins.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2InstanceControl"
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      },
      {
        Sid    = "RDSControl"
        Effect = "Allow"
        Action = [
          "rds:ModifyDBInstance",
          "rds:DescribeDBInstances",
          "rds:RebootDBInstance"
        ]
        Resource = "*"
      },
      {
        Sid    = "AutoScalingControl"
        Effect = "Allow"
        Action = [
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:DescribeAutoScalingGroups"
        ]
        Resource = "*"
      },
      {
        Sid    = "ELBRead"
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:Describe*"
        ]
        Resource = "*"
      },
      {
        Sid    = "Route53Control"
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListHostedZones"
        ]
        Resource = "*"
      },

      # ============================================================
      # v2 추가 — Phase 4 Jenkins 파이프라인용 권한
      # ⚠ POC용 광범위 권한 포함. Phase 6에서 최소권한 리팩터링 필요.
      # ============================================================

      # [1] ASG Instance Refresh (Deploy/Rollback 파이프라인 핵심)
      {
        Sid    = "ASGInstanceRefresh"
        Effect = "Allow"
        Action = [
          "autoscaling:StartInstanceRefresh",
          "autoscaling:DescribeInstanceRefreshes",
          "autoscaling:CancelInstanceRefresh"
        ]
        Resource = "*"
      },

      # [2] Launch Template 관리 (Terraform이 LT 새 버전 만들 때 + Rollback)
      {
        Sid    = "LaunchTemplateManage"
        Effect = "Allow"
        Action = [
          "ec2:CreateLaunchTemplateVersion",
          "ec2:ModifyLaunchTemplate",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Resource = "*"
      },

      # [3] Terraform State Backend (terraform init 필수)
      {
        Sid    = "TerraformStateBackend"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::hybrid-dr-tfstate-soldesk803",
          "arn:aws:s3:::hybrid-dr-tfstate-soldesk803/*"
        ]
      },

      # [4] Terraform State Lock (DynamoDB)
      # NOTE: Region 하드코딩. 멀티 리전 시 변수화 필요.
      {
        Sid    = "TerraformStateLock"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:ap-northeast-2:*:table/hybrid-dr-tfstate-lock"
      },

      # [5] Terraform 전체 실행 권한 (POC용 광범위)
      # ⚠ POC용도. Phase 6에서 AssumeRole 패턴으로 최소권한 리팩터링 필요.
      {
        Sid    = "TerraformApplyBroad"
        Effect = "Allow"
        Action = [
          "ec2:*",
          "rds:*",
          "elasticloadbalancing:*",
          "route53:*",
          "autoscaling:*"
        ]
        Resource = "*"
      },

      # [6] IAM 관리 (project-* 범위 제한, 계정 장악 방지)
      {
        Sid    = "IAMManageProjectResources"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRolePolicy",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:GetInstanceProfile",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:TagInstanceProfile",
          "iam:UntagInstanceProfile",
          "iam:ListInstanceProfilesForRole"
        ]
        Resource = [
          "arn:aws:iam::*:role/project-*",
          "arn:aws:iam::*:instance-profile/project-*"
        ]
      },

      # [7] PassRole — 프로젝트 Role만, EC2 서비스에만 부착
      {
        Sid    = "PassRoleScoped"
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = [
          "arn:aws:iam::*:role/project-springboot-role",
          "arn:aws:iam::*:role/project-jenkins-role"
        ]
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ec2.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_cloudwatch" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.project_name}-jenkins-profile"
  role = aws_iam_role.jenkins.name

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-jenkins-profile"
  })
}
