variable "aws_region" {
  description = "AWS region for the EKS cluster."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name and project tag value."
  type        = string
  default     = "csnp-lab10"
}

variable "private_app_subnet_ids" {
  description = "Private application subnet IDs used by the cluster and node group."
  type        = list(string)
}

variable "public_access_cidrs" {
  description = "Admin public IPs only, each in CIDR format."
  type        = list(string)
}

variable "kubernetes_version" {
  description = "EKS Kubernetes control plane version."
  type        = string
  default     = "1.32"
}

variable "node_instance_types" {
  description = "EC2 instance types allowed for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}
