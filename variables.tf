variable "project" {
  description = "project_name"
  default     = "test"
}

variable "region" {
  description = "region"
  default     = "ap-northeast-2"
}

variable "vpc_cidr" {
  description = "vpc_cidr"
  default     = "10.10.10.0/24"
}

variable "public_subnet" {
  description = "public_subnet"
  default = [
    "10.10.10.0/27",
    "10.10.10.32/27",
    "10.10.10.64/27",
    "10.10.10.96/27"
  ]
}

variable "private_subnet" {
  description = "private_subnet"
  default = [
    "10.10.10.128/27",
    "10.10.10.160/27",
    "10.10.10.192/27",
    "10.10.10.224/27"
  ]
}

variable "default_domain" {
  description = "default_domain"
  default     = "cloudcoke.site"
}

variable "my_ec2_type" {
  description = "my_ec2_type"
  default     = "t2.micro"
}

variable "my_key_pair" {
  description = "my_key_pair"
  default     = "my-ec2-keypair"
}

variable "my_acm" {
  description = "my_acm"
  default     = "arn:aws:acm:ap-northeast-2:620872919682:certificate/269e407d-dfb7-4cba-ae50-8bf604490418"
}