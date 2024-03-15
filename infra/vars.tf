variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "mais-todos"
}

variable "app_environment" {
  type    = string
  default = "mais-todos"
}

variable "vpc_cidr_block" {
  type        = string
  default     = "10.10.0.0/16"
  description = "CIDR block range for vpc"
}

variable "public_subnet_cidr_blocks" {
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24"]
  description = "CIDR block range for public subnet"
}

variable "private_subnet_cidr_blocks_app" {
  type        = list(string)
  default     = ["10.10.3.0/24", "10.10.4.0/24"]
  description = "CIDR block range for private subnet"
}

variable "private_subnet_cidr_blocks_db" {
  type        = list(string)
  default     = ["10.10.5.0/24", "10.10.6.0/24"]
  description = "CIDR block range for private subnet"
}

variable "availability_zones" {
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
  description = "List of availability zones for selected region"
}


variable "linux_ami_id" {
  type        = string
  description = "EC2 instance AMI for Linux Server"
  default     = "ami-07d9b9ddc6cd8dd30"
}

variable "linux_instance_type" {
  type        = string
  description = "EC2 instance type for Linux Server"
  default     = "t3a.micro"
}

variable "linux_associate_public_ip" {
  type        = bool
  description = "Associate a public IP address to the EC2 instance"
  default     = false
}

variable "linux_root_volume_size" {
  type        = number
  description = "Volumen size of root volumen of Linux Server"
  default     = "30"
}

variable "linux_root_volume_type" {
  type        = string
  description = "Volumen type of root volumen of Linux Server."
  default     = "gp3"
}



