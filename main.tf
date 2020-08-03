// ======================================================
// Networking configuration   
// ======================================================
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags {
    Name = var.cluster_name
    Environment = var.cluster_name
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.main_vpc.id
  cidr_block = "10.0.100.0/24"
  availability_zone = "${var.region}${var.az}"
  map_public_ip_on_launch = true

  tags {
    Name = var.cluster_name
    Environment = var.cluster_name
  }
}

resource "aws_internet_gateway" "main_gw" {
  vpc_id = aws_vpc.main_vpc.id

  tags {
    Name = var.cluster_name
    Environment = var.cluster_name
  }
}

resource "aws_route_table" "gw_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_gw.id
  }

  depends_on = [aws_internet_gateway.main_gw]

  tags {
    Name = var.cluster_name
    Environment = var.cluster_name
  }
}

resource "aws_route_table_association" "public_route_table" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.gw_route_table.id
}
// ======================================================

// ======================================================
// Security Group and its ingress/egress rules   
// ======================================================
resource "aws_security_group" "k8s_sg" {
  name = var.cluster_name
  description = "Allow inbound and outbound traffic"
  vpc_id = aws_vpc.main_vpc.id

  tags {
    Name = var.cluster_name
    Environment = var.cluster_name
  }
}

resource "aws_security_group_rule" "allow_all_from_self" {
  type            = "ingress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  source_security_group_id = aws_security_group.k8s_sg.id
  security_group_id = aws_security_group.k8s_sg.id
}

resource "aws_security_group_rule" "allow_ssh_from_admin" {
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  cidr_blocks     = split(",", var.admin_cidr_blocks)
  security_group_id = aws_security_group.k8s_sg.id
}

resource "aws_security_group_rule" "allow_k8s_from_admin" {
  type            = "ingress"
  from_port       = 6443
  to_port         = 6443
  protocol        = "tcp"
  cidr_blocks     = split(",", var.admin_cidr_blocks)
  security_group_id = aws_security_group.k8s_sg.id
}

resource "aws_security_group_rule" "allow_https_from_web" {
  type            = "ingress"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]

  security_group_id = aws_security_group.k8s_sg.id
}

resource "aws_security_group_rule" "allow_http_from_web" {
  type            = "ingress"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]

  security_group_id = aws_security_group.k8s_sg.id
}

resource "aws_security_group_rule" "allow_all_out" {
  type            = "egress"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]

  security_group_id = aws_security_group.k8s_sg.id
}
// ======================================================

// ======================================================
// S3 resources            
// ======================================================
resource "aws_s3_bucket" "s3_bucket" {
  bucket_prefix   = var.cluster_name
  force_destroy   = "true"

  tags {
    Environment = var.cluster_name
  }

  lifecycle_rule {
    id      = "etcd-backups"
    prefix  = "etcd-backups/"
    enabled = true

    expiration {
      days = 7
    }
  }
}

resource "aws_s3_bucket_object" "external_dns_manifest" {
  count  = var.external_dns_enabled
  bucket = aws_s3_bucket.s3_bucket.id
  key    = "manifests/external-dns.yaml"
  source = "manifests/external-dns.yaml"
  etag   = md5(file("manifests/external-dns.yaml"))
}

resource "aws_s3_bucket_object" "ebs_storage_class_manifest" {
  bucket = aws_s3_bucket.s3_bucket.id
  key    = "manifests/ebs-storage-class.yaml"
  source = "manifests/ebs-storage-class.yaml"
  etag   = md5(file("manifests/ebs-storage-class.yaml"))
}

resource "aws_s3_bucket_object" "nginx_ingress_manifest" {
  count  = var.nginx_ingress_enabled
  bucket = aws_s3_bucket.s3_bucket.id
  key    = "manifests/nginx-ingress-mandatory.yaml"
  source = "manifests/nginx-ingress-mandatory.yaml"
  etag   = md5(file("manifests/nginx-ingress-mandatory.yaml"))
}

data "template_file" "nginx_ingress_nodeport_tpl" {
  count  = var.nginx_ingress_enabled
  template = file("manifests/nginx-ingress-nodeport.yaml.tmpl")
  vars {
    nginx_ingress_domain = var.nginx_ingress_domain
  }
}

resource "aws_s3_bucket_object" "nginx_ingress_nodeport_manifest" {
  count  = var.nginx_ingress_enabled
  bucket = aws_s3_bucket.s3_bucket.id
  key    = "manifests/nginx-ingress-nodeport.yaml"
  content = data.template_file.nginx_ingress_nodeport_tpl.rendered
  etag   = md5(data.template_file.nginx_ingress_nodeport_tpl.rendered)
}

data "template_file" "cluster_autoscaler_tpl" {
  template = file("manifests/cluster-autoscaler-autodiscover.yaml.tmpl")
  vars {
    cluster_name = var.cluster_name
    cluster_region = var.region
  }
}

resource "aws_s3_bucket_object" "cluster_autoscaler_manifest" {
  count  = var.cluster_autoscaler_enabled
  bucket = aws_s3_bucket.s3_bucket.id
  key    = "manifests/cluster-autoscaler-autodiscover.yaml"
  content = data.template_file.cluster_autoscaler_tpl.rendered
  etag   = md5(data.template_file.cluster_autoscaler_tpl.rendered)
}

data "template_file" "cert_manager_issuer_tpl" {
  template = file("manifests/cert-manager-issuer.yaml.tmpl")
  vars {
    cert_manager_email = var.cert_manager_email
  }
}

resource "aws_s3_bucket_object" "cert_manager_issuer_manifest" {
  count  = var.cert_manager_enabled
  bucket = aws_s3_bucket.s3_bucket.id
  key    = "manifests/cert-manager-issuer.yaml"
  content = data.template_file.cert_manager_issuer_tpl.rendered
  etag   = md5(data.template_file.cert_manager_issuer_tpl.rendered)
}
// ======================================================

// ======================================================
// Bash scripts to install K8s      
// ======================================================
data "template_file" "master_userdata_tpl" {
  template = file("k8s_master.sh")

  vars {
    k8stoken = local.k8stoken
    clustername = var.cluster_name
    s3bucket = aws_s3_bucket.s3_bucket.id
    backupcron = var.backup_cron_expression
    k8sversion = var.kubernetes_version
    backupenabled = var.backup_enabled
    certmanagerenabled = var.cert_manager_enabled
  }
}

data "template_file" "worker_userdata_tpl" {
  template = file("k8s_worker.sh")

  vars {
    k8stoken = local.k8stoken
    masterIP = "10.0.100.4"
    k8sversion = var.kubernetes_version
  }
}
// ======================================================

data "aws_ami" "latest_ami" {
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-instance/ubuntu-bionic-18.04-amd64-server-*"]
  }

  most_recent = true
  owners      = ["099720109477"] # Ubuntu
}

// ======================================================
// IAM configuration      
// ======================================================
resource "aws_iam_role" "ec2_iam_role" {
  name = "${var.cluster_name}_instance_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2_role_policy_att" {
  role       = aws_iam_role.ec2_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_policy" "ec2_ebs_policy" {
  name        = "${var.cluster_name}_cluster_policy"
  path        = "/"
  description = "Policy for ${var.cluster_name} cluster to allow dynamic provisioning of EBS persistent volumes"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AttachVolume",
        "ec2:CreateVolume",
        "ec2:DeleteVolume",
        "ec2:DescribeInstances",
        "ec2:DescribeRouteTables",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVolumes",
        "ec2:DescribeVolumesModifications",
        "ec2:DescribeVpcs",
        "elasticloadbalancing:DescribeLoadBalancers",
        "ec2:DetachVolume",
        "ec2:ModifyVolume",
        "ec2:CreateTags"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2_ebs_policy_att" {
  role       = aws_iam_role.ec2_iam_role.name
  policy_arn = aws_iam_policy.ec2_ebs_policy.arn
}

resource "aws_iam_policy" "autoscaling_gral_policy" {
  count       = var.cluster_autoscaler_enabled
  name        = "${var.cluster_name}_autoscaling_policy"
  path        = "/"
  description = "Policy for ${var.cluster_name} cluster to allow cluster autoscaling to work"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "autoscaling_gral_policy_att" {
  count      = var.cluster_autoscaler_enabled
  role       = aws_iam_role.ec2_iam_role.name
  policy_arn = aws_iam_policy.autoscaling_gral_policy.arn
}

resource "aws_iam_policy" "s3_bucket_policy" {
  name        = "${var.cluster_name}_s3_bucket_policy"
  path        = "/"
  description = "Policy for ${var.cluster_name} cluster to allow access to the Backup S3 Bucket"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["s3:ListBucket"],
            "Resource": ["${aws_s3_bucket.s3_bucket.arn}"]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListObjects"
            ],
            "Resource": ["${aws_s3_bucket.s3_bucket.arn}/*"]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "s3_bucket_policy_att" {
  role       = aws_iam_role.ec2_iam_role.name
  policy_arn = aws_iam_policy.s3_bucket_policy.arn
}

resource "aws_iam_policy" "route53_policy" {
  count       = var.external_dns_enabled
  name        = "${var.cluster_name}_route53_policy"
  path        = "/"
  description = "Policy for ${var.cluster_name} cluster to allow access to Route 53 for DNS record creation"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["route53:*"],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "route53_policy_att" {
  count      = var.external_dns_enabled
  role       = aws_iam_role.ec2_iam_role.name
  policy_arn = aws_iam_policy.route53_policy.arn
}

resource "aws_iam_instance_profile" "iam_instance_profile" {
  name = "${var.cluster_name}_instance_profile"
  role = aws_iam_role.ec2_iam_role.name
}
// ======================================================

// ======================================================
// EC2 Spot Instances  
// ======================================================
resource "aws_spot_instance_request" "master" {
  ami                     = data.aws_ami.latest_ami.id
  instance_type           = var.master_instance_type
  subnet_id               = aws_subnet.public_subnet.id
  user_data               = data.template_file.master_userdata_tpl.rendered
  key_name                = var.k8s_ssh_key
  iam_instance_profile    = aws_iam_instance_profile.iam_instance_profile.name
  vpc_security_group_ids  = [aws_security_group.k8s_sg.id]
  spot_price              = var.master_spot_price
  valid_until             = "9999-12-25T12:00:00Z"
  wait_for_fulfillment    = true
  private_ip              = "10.0.100.4"

  depends_on = [aws_internet_gateway.main_gw]

  tags {
    Name = "${var.cluster_name}_master"
    Environment = var.cluster_name
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

# Spot for workers
resource "aws_launch_template" "worker" {
  iam_instance_profile        = { name = "${aws_iam_instance_profile.iam_instance_profile.name}" }
  image_id                    = data.aws_ami.latest_ami.id
  name                        = "${var.cluster_name}_worker"
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  key_name                    = var.k8s_ssh_key
  instance_type               = var.worker_instance_type
  user_data                   = base64encode(data.template_file.worker_userdata_tpl.rendered)
  ebs_optimized               = false

  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = var.worker_spot_price
    }
  }
}

# Autoscaling Group for workers
resource "aws_autoscaling_group" "worker_asg" {
  max_size             = var.max_worker_count
  min_size             = var.min_worker_count
  name                 = "${var.cluster_name}_worker"
  vpc_zone_identifier  = [aws_subnet.public_subnet.id]

  launch_template {
    id = aws_launch_template.worker.id
    version = "$$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}_worker"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.cluster_name
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = true
  }
}
// ======================================================
