# create an IAM role for the control plane
resource "aws_iam_role" "cluster" {
    name = "${var.name}-cluster-role"
    assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json
}

# allow EKS to assume the IAM role
data "aws_iam_policy_document" "cluster_assume_role" {
    statement {
      effect = "Allow"
      actions = ["sts:AssumeRole"]
      principals {
        type = "Service"
        identifiers = ["eks.amazonaws.com"]
      }
    }
}

# attache the permisions the IAM role needs
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role = aws_iam_role.cluster.name
}

# since this code is only for learning, use the default VPC and subnets
# for real-world use cases, you should use a custom VPC and private subnets
data "aws_vpc" "default" {
    default = true
}

data "aws_subnets" "default" {
    filter {
        name = "vpc-id"
        values = [data.aws_vpc.default.id]
    }
}

resource "aws_eks_cluster" "cluster" {
  name = var.name
  role_arn = aws_iam_role.cluster.arn
  version = "1.23"

  vpc_config {
    subnet_ids = data.aws_subnets.default.ids
  }

  # ensure that IAM role permissions are created before and deleted after
  # the EKS Cluster. Otherwise, EKS will not be able to properly delete
  # EKS managed EC2 infrastructure such as Security Groups
  depends_on = [ 
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy
   ]
}

# create and IAM role for the node group
resource "aws_iam_role" "node_group" {
    name = "${var.name}-node-group"
    assume_role_policy = data.aws_iam_policy_document.node_assume_role.json
}

# allow EC2 instances to assume the IAM role
data "aws_iam_policy_document" "node_assume_role" {
    statement {
        effect = "Allow"
        actions = ["sts:AssumeRole"]
        principals {
            type = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
    }
}

# attach the permission the node group needs
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    role = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    role = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    role = aws_iam_role.node_group.name
}

resource "aws_eks_node_group" "nodes" {
    cluster_name = aws_eks_cluster.cluster.name
    node_group_name = var.name
    node_role_arn = aws_iam_role.node_group.arn
    subnet_ids = data.aws_subnets.default.ids
    instance_types = var.instance_types

    scaling_config {
      min_size = var.min_size
      max_size = var.max_size
      desired_size = var.desired_size
    }

    # ensure that IAM role permissions are created befor and deleted after
    # the EKS node group. otherwise, EKS will not be able to properly
    # delete EC2 instances and elastic network interfaces
    depends_on = [
        aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
        aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
        aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    ]
}