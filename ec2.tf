# ubuntu 이미지 지정
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20230517"]
  }
}

# front 인스턴스 생성
resource "aws_instance" "front" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.my_ec2_type
  subnet_id                   = aws_subnet.public_subnet["10.10.10.0/27"].id
  key_name                    = var.my_key_pair
  vpc_security_group_ids      = [aws_security_group.default_security_group.id]
  associate_public_ip_address = true

  tags = {
    Name = "front-server"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${path.module}/${var.my_key_pair}.pem")
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "scripts/front.sh"
    destination = "/tmp/front.sh"
  }
}

# front 서버 설정
# resource "null_resource" "front_https" {
#   depends_on = [aws_route53_record.my_www_record]

#   connection {
#     type        = "ssh"
#     user        = "ubuntu"
#     private_key = file("${path.module}/${var.my_key_pair}.pem")
#     host        = aws_eip.front_eip.public_ip
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "sudo bash /tmp/front.sh"
#     ]
#   }
# }

# back 인스턴스 생성
resource "aws_instance" "back" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.my_ec2_type
  subnet_id                   = aws_subnet.public_subnet["10.10.10.64/27"].id
  key_name                    = var.my_key_pair
  vpc_security_group_ids      = [aws_security_group.default_security_group.id]
  associate_public_ip_address = true

  tags = {
    Name = "back-server"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${path.module}/${var.my_key_pair}.pem")
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "scripts/back.sh"
    destination = "/tmp/back.sh"
  }
}

# back 서버 설정
resource "null_resource" "back_https" {
  depends_on = [aws_route53_record.my_api_record]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${path.module}/${var.my_key_pair}.pem")
    host        = aws_eip.back_eip.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo bash /tmp/back.sh"
    ]
  }
}

# db 인스턴스 생성
resource "aws_instance" "db" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.my_ec2_type
  subnet_id              = aws_subnet.private_subnet["10.10.10.128/27"].id
  key_name               = var.my_key_pair
  vpc_security_group_ids = [aws_security_group.mongo_db_sg.id]

  tags = {
    Name = "db-server"
  }

  user_data = file("${path.module}/scripts/mongodb.sh")
}