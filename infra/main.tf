# VPC Network Setup
resource "aws_vpc" "mais_todos_vpc" {
  enable_dns_support   = true
  enable_dns_hostnames = true
  cidr_block           = var.vpc_cidr_block
  tags = {
    Name = "${var.project_name}-vpc"
  }
}


# Setup IGW and NAT
resource "aws_internet_gateway" "mais_todos_igw" {
  vpc_id = aws_vpc.mais_todos_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_eip" "mais_todos_eip" {
  # vpc = true

  tags = {
    Name = "${var.project_name}-eip"
  }
}

resource "aws_nat_gateway" "mais_todos_nat" {
  allocation_id = aws_eip.mais_todos_eip.id
  subnet_id     = aws_subnet.mais_todos_public_subnet[0].id

  tags = {
    Name = "${var.project_name}-nat"
  }

  depends_on = [aws_internet_gateway.mais_todos_igw]
}

resource "aws_subnet" "mais_todos_public_subnet" {
  count                   = length(var.public_subnet_cidr_blocks)
  vpc_id                  = aws_vpc.mais_todos_vpc.id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    "Name" = "${var.project_name}-public-subnet"
  }
}

resource "aws_subnet" "mais_todos_private_subnet_app" {
  count             = length(var.private_subnet_cidr_blocks_app)
  vpc_id            = aws_vpc.mais_todos_vpc.id
  cidr_block        = var.private_subnet_cidr_blocks_app[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-private-subnet-app"
  }
}

resource "aws_subnet" "mais_todos_private_subnet_db" {
  count             = length(var.private_subnet_cidr_blocks_db)
  vpc_id            = aws_vpc.mais_todos_vpc.id
  cidr_block        = var.private_subnet_cidr_blocks_db[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-private-subnet-db"
  }
}

# Setup route table and association
resource "aws_route_table" "mais_todos_private_app_rt" {
  vpc_id = aws_vpc.mais_todos_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.mais_todos_nat.id
  }

  tags = {
    Name = "${var.project_name}-private-app-rt"
  }
}

resource "aws_route_table" "mais_todos_private_db_rt" {
  vpc_id = aws_vpc.mais_todos_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.mais_todos_nat.id
  }

  tags = {
    Name = "${var.project_name}-private-db-rt"
  }
}


resource "aws_route_table" "mais_todos_public_rt" {
  vpc_id = aws_vpc.mais_todos_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mais_todos_igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "mais_todos_public_subnet_rta" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.mais_todos_public_subnet[count.index].id
  route_table_id = aws_route_table.mais_todos_public_rt.id
}

resource "aws_route_table_association" "mais_todos_private_subnet_app_rta" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.mais_todos_private_subnet_app[count.index].id
  route_table_id = aws_route_table.mais_todos_private_app_rt.id
}

resource "aws_route_table_association" "mais_todos_private_subnet_db_rta" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.mais_todos_private_subnet_db[count.index].id
  route_table_id = aws_route_table.mais_todos_private_db_rt.id
}



# Security Groups

# Create public facing security group
resource "aws_security_group" "mais_todos_public_facing_sg" {
  vpc_id = aws_vpc.mais_todos_vpc.id
  name   = "mais_todos_public_facing_sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Internet - Porta 22"
    # Allow traffic from public subnet
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-public-facing-sg"
  }
}

# Create private facing security group for app
resource "aws_security_group" "mais_todos_private_facing_app_sg" {
  vpc_id = aws_vpc.mais_todos_vpc.id
  name   = "${var.project_name}-private-facing-app-sg"

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = flatten([var.private_subnet_cidr_blocks_app, var.private_subnet_cidr_blocks_db])
    description = "Rede Privada - All TCP"
    # Allow traffic from private subnets
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups  = ["${aws_security_group.mais_todos_public_facing_sg.id}"]
    description = "SG Proxy - Porta 22"
    # Allow traffic from private subnets
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-private-facing-app-sg"
  }
}

# Create private facing security group for db
resource "aws_security_group" "mais_todos_private_facing_db_sg" {
  vpc_id = aws_vpc.mais_todos_vpc.id
  name   = "${var.project_name}-private-facing-db-sg"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups  = ["${aws_security_group.mais_todos_private_facing_app_sg.id}"]
    description = "SG APP - Porta 5432"
    # Allow traffic from private subnets
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups  = ["${aws_security_group.mais_todos_public_facing_sg.id}"]
    description = "EC2 Proxy - Porta 22"
    # Allow traffic from private subnets
  }  

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-private-facing-db-sg"
  }
}


# EC2

# Create EC2 Instances

# Generates a secure private key and encodes it as PEM
resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Create the Key Pair
resource "aws_key_pair" "key_pair" {
  key_name   = "ec2-key-pair"
  public_key = tls_private_key.key_pair.public_key_openssh
}
# Save file
resource "local_file" "ssh_key" {
  filename = "${aws_key_pair.key_pair.key_name}.pem"
  content  = tls_private_key.key_pair.private_key_pem
}


# K3S Master 1
resource "aws_instance" "k3s_master_1" {
  ami                         = var.linux_ami_id
  instance_type               = var.linux_instance_type
  subnet_id                   = aws_subnet.mais_todos_private_subnet_app[0].id
  vpc_security_group_ids      = [aws_security_group.mais_todos_private_facing_app_sg.id]
  associate_public_ip_address = var.linux_associate_public_ip
  source_dest_check           = false
  key_name                    = aws_key_pair.key_pair.key_name

  # root disk
  root_block_device {
    volume_size           = var.linux_root_volume_size
    volume_type           = var.linux_root_volume_type
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name        = "k3s-master-01"
    Environment = var.app_environment
  }
}

# # K3S Master 2
# resource "aws_instance" "k3s_master_2" {
#   ami = var.linux_ami_id
#   instance_type = var.linux_instance_type
#   subnet_id = aws_subnet.mais_todos_private_subnet_app[1].id
#   vpc_security_group_ids = [aws_security_group.mais_todos_private_facing_sg.id]
#   associate_public_ip_address = var.linux_associate_public_ip
#   source_dest_check = false
#   key_name = aws_key_pair.key_pair.key_name
#   # user_data = file("aws-user-data.sh")

#   # root disk
#   root_block_device {
#     volume_size           = var.linux_root_volume_size
#     volume_type           = var.linux_root_volume_type
#     delete_on_termination = true
#     encrypted             = true
#   }

#   tags = {
#     Name        = "k3s-master-02"
#     Environment = var.app_environment
#   }
# }

# K3S Worker 1
resource "aws_instance" "k3s_worker_1" {
  ami                         = var.linux_ami_id
  instance_type               = var.linux_instance_type
  subnet_id                   = aws_subnet.mais_todos_private_subnet_app[0].id
  vpc_security_group_ids      = [aws_security_group.mais_todos_private_facing_app_sg.id]
  associate_public_ip_address = var.linux_associate_public_ip
  source_dest_check           = false
  key_name                    = aws_key_pair.key_pair.key_name

  # root disk
  root_block_device {
    volume_size           = var.linux_root_volume_size
    volume_type           = var.linux_root_volume_type
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name        = "k3s-worker-01"
    Environment = var.app_environment
  }
}


# K3S Worker 2
resource "aws_instance" "k3s_worker_2" {
  ami                         = var.linux_ami_id
  instance_type               = var.linux_instance_type
  subnet_id                   = aws_subnet.mais_todos_private_subnet_app[1].id
  vpc_security_group_ids      = [aws_security_group.mais_todos_private_facing_app_sg.id]
  associate_public_ip_address = var.linux_associate_public_ip
  source_dest_check           = false
  key_name                    = aws_key_pair.key_pair.key_name

  # root disk
  root_block_device {
    volume_size           = var.linux_root_volume_size
    volume_type           = var.linux_root_volume_type
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name        = "k3s-worker-02"
    Environment = var.app_environment
  }
}


# EC2 Database
resource "aws_instance" "ec2_database" {
  ami                         = var.linux_ami_id
  instance_type               = var.linux_instance_type
  subnet_id                   = aws_subnet.mais_todos_private_subnet_db[0].id
  vpc_security_group_ids      = [aws_security_group.mais_todos_private_facing_db_sg.id]
  associate_public_ip_address = var.linux_associate_public_ip
  source_dest_check           = false
  key_name                    = aws_key_pair.key_pair.key_name

  # root disk
  root_block_device {
    volume_size           = var.linux_root_volume_size
    volume_type           = var.linux_root_volume_type
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name        = "db-postgresql"
    Environment = var.app_environment
  }
}


# EC2 Proxy Reverso
resource "aws_instance" "ec2_proxy" {
  ami                         = var.linux_ami_id
  instance_type               = "t3a.small"
  subnet_id                   = aws_subnet.mais_todos_public_subnet[0].id
  vpc_security_group_ids      = [aws_security_group.mais_todos_public_facing_sg.id]
  associate_public_ip_address = true
  source_dest_check           = false
  key_name                    = aws_key_pair.key_pair.key_name

  # root disk
  root_block_device {
    volume_size           = var.linux_root_volume_size
    volume_type           = var.linux_root_volume_type
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name        = "nginx-proxy"
    Environment = var.app_environment
  }
}

