# ubuntu 이미지 지정
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20230517"]
  }
}

# nat 인스턴스 생성
resource "aws_instance" "nat_gateway" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.my_ec2_type
  subnet_id                   = aws_subnet.public_subnet[0].id
  key_name                    = var.my_key_pair
  vpc_security_group_ids      = [aws_security_group.nat_gateway.id]
  associate_public_ip_address = true
  source_dest_check           = false

  user_data = file("${path.module}/scripts/nat_settings.sh")

  tags = {
    Name = "nat_gateway"
  }
}

# front main 인스턴스 생성
resource "aws_instance" "front" {
  count                       = length(var.public_subnet) / 2
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.my_ec2_type
  subnet_id                   = aws_subnet.public_subnet[count.index].id
  key_name                    = var.my_key_pair
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true

  tags = {
    Name = "front-${count.index}"
  }

  user_data = file("${path.module}/scripts/front.sh")
}

resource "aws_instance" "back" {
  count                       = length(var.public_subnet) / 2
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.my_ec2_type
  subnet_id                   = aws_subnet.public_subnet[count.index + 2].id
  key_name                    = var.my_key_pair
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true

  tags = {
    Name = "back-${count.index}"
  }

}

resource "null_resource" "back" {
  count = length(var.public_subnet) / 2

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${path.module}/${var.my_key_pair}.pem")
    host        = aws_instance.back[count.index].public_ip
  }

  provisioner "file" {
    source      = "scripts/back.sh"
    destination = "/tmp/back.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "export HOSTNAME=${aws_instance.back[count.index].public_dns}",
      "sudo bash /tmp/back.sh",
    ]
  }
}

# db 인스턴스 생성
resource "aws_instance" "db" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.my_ec2_type
  subnet_id              = aws_subnet.private_subnet[0].id
  key_name               = var.my_key_pair
  vpc_security_group_ids = [aws_security_group.mongo_db_sg.id]

  tags = {
    Name = "db-server"
  }

  user_data = templatefile("${path.module}/scripts/mongodb.tftpl", { user_name = "cloudcoke", passwd = "1" })
}