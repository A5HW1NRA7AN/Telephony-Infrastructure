variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Name of the SSH key pair to associate with Jenkins EC2"
  type        = string
  default     = "jenkins-key-pair"
}

variable "allowed_http_ingress_cidrs" {
  description = "CIDR blocks allowed to access the Jenkins UI (port 8080)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
