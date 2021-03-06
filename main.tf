# プロバイダーの設定
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = var.region
}

# リソースの設定
resource "aws_vpc" "myVPC" {
  cidr_block = "10.1.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = "true"
  enable_dns_hostnames = "false"
  tags = {
    Name = "myVPC"
  }
}

# internet gatewayの設定
resource "aws_internet_gateway" "myGW" {
  # myVPCのid属性を参照
  vpc_id = aws_vpc.myVPC.id
  # 他リソースの属性を参照する場合、参照先のリソースが参照元のリソースより先に作成されている必要がある
  # Terrafromではこのようなリソース間の依存関係を自動的に解決してくれるから、基本的には依存関係を明示する必要はない
  # ただmyVPCに依存することを明示することも可能
  # depends_on = aws_vpc.myVPC
}

# subnetの設定
resource "aws_subnet" "public-a" {
  vpc_id = aws_vpc.myVPC.id
  cidr_block = "10.1.1.0/24"
  availability_zone = "ap-northeast-1a"
}

# route tabe の設定
resource "aws_route_table" "public-route" {
  vpc_id = aws_vpc.myVPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myGW.id
  }
}

resource "aws_route_table_association" "puclic-a" {
  subnet_id = aws_subnet.public-a.id
  route_table_id = aws_route_table.public-route.id
}

# security groupの設定
resource "aws_security_group" "admin" {
  name = "admin"
  description = "Allow SSH inbound traffic"
  vpc_id = aws_vpc.myVPC.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# sshで使用する鍵ペアを設定
resource "aws_key_pair" "my-key-pair" {
  key_name = var.key_name
  public_key = file(var.public_key)
}

# ec2の設定
resource "aws_instance" "cm-test" {
  ami = var.images.ap-northeast-1
  instance_type = "t2.micro"
  key_name = var.key_name
  vpc_security_group_ids = [
    aws_security_group.admin.id
  ]
  subnet_id = aws_subnet.public-a.id
  associate_public_ip_address = "true"
  root_block_device {
    volume_type = "gp2"
    volume_size = "20"
  }
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "gp2"
    volume_size = "100"
  }
  tags = {
    Name = "cm-test"
  }
}
