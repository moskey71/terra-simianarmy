provider "aws" {
  region = "${var.region}"
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user-data.tpl")}"

  vars {
    s3configbucket = "${var.s3configbucket}"
       }
}

data "aws_ami" "ubuntu_svr" {
  most_recent = true

  filter {
    name = "name"

    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_launch_configuration" "as_conf" {
  name_prefix          = "${var.tag_name}-lc"
  image_id             = "${data.aws_ami.ubuntu_svr.id}"
  instance_type        = "${var.instance_type}"
  security_groups      = ["${aws_security_group.instance-sg1.id}", "${var.security_groups}"]
  key_name             = "${var.key_name}"
  user_data            = "${data.template_file.user_data.rendered}"
  iam_instance_profile = "${aws_iam_instance_profile.simianarmy.id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  name_prefix          = "${var.tag_name}-asg"
  launch_configuration = "${aws_launch_configuration.as_conf.name}"
  min_size             = 1
  max_size             = 1
  vpc_zone_identifier  = ["${var.private_subnets}"]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.tag_name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Terraform"
    value               = "true"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "instance-sg1" {
  name_prefix = "${var.tag_name}"
  description = "Security group for accessing simianarmy"

  vpc_id = "${var.vpcid}"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name      = "${var.tag_name}"
    Terraform = "True"
  }
}

#Deploy SimpleDB
resource "aws_simpledb_domain" "simianarmy" {
  name = "SIMIAN_ARMY"
}

resource "aws_iam_role" "simianarmy" {
  name_prefix = "simianarmy"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "simianarmy" {
  name_prefix = "simianarmy"
  roles       = ["${aws_iam_role.simianarmy.id}"]
}

resource "aws_iam_role_policy" "simianarmy" {
  name_prefix = "simianarmy"
  role        = "${aws_iam_role.simianarmy.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
         "ec2:DescribeImages",
         "ec2:DescribeInstances",
         "ec2:DescribeSnapshots",
         "ec2:DescribeVolumes",
         "ses:SendEmail",
         "elasticloadbalancing:DescribeLoadBalancerPolicies",
         "elasticloadbalancing:DescribeLoadBalancerPolicyTypes",
         "elasticloadbalancing:DescribeInstanceHealth",
         "elasticloadbalancing:DescribeLoadBalancerAttributes",
         "elasticloadbalancing:DescribeSSLPolicies",
         "elasticloadbalancing:DescribeLoadBalancers",
         "elasticloadbalancing:DescribeTargetGroupAttributes",
         "elasticloadbalancing:DescribeListeners",
         "elasticloadbalancing:DescribeTags",
         "elasticloadbalancing:DescribeAccountLimits",
         "elasticloadbalancing:DescribeTargetHealth",
         "elasticloadbalancing:DescribeTargetGroups",
         "elasticloadbalancing:DescribeListenerCertificates",
         "elasticloadbalancing:DescribeRules"
       ],
       "Effect": "Allow",
       "Resource": "*"
     },
     {
         "Action": [
         "autoscaling:DescribeAutoScalingGroups",
         "autoscaling:DescribeAutoScalingInstances",
         "autoscaling:DescribeLaunchConfigurations"
       ],
       "Effect": "Allow",
       "Resource": "*"
     },
     {
         "Action":
         "s3:*",

       "Effect": "Allow",
       "Resource": [
         "arn:aws:s3:::${var.s3configbucket}",
         "arn:aws:s3:::${var.s3configbucket}/*"
     ]
     },
     {
         "Action": [
         "ses:SendEmail",
         "ses:SendRawEmail"
           ],
          "Effect": "Allow",
          "Resource": "*"
       },
     {
         "Action": [
         "sdb:BatchDeleteAttributes",
         "sdb:BatchPutAttributes",
         "sdb:DomainMetadata",
         "sdb:GetAttributes",
         "sdb:PutAttributes",
         "sdb:ListDomains",
         "sdb:CreateDomain",
         "sdb:Select"
       ],
       "Effect": "Allow",
       "Resource": "*"
    }
  ]
}
EOF
}
