# ubuntu 이미지 지정
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20230517"]
  }
}

# front main 인스턴스 생성
resource "aws_instance" "front_main" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.my_ec2_type
  subnet_id                   = aws_subnet.public_subnet["10.10.10.0/27"].id
  key_name                    = var.my_key_pair
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true

  tags = {
    Name = "front_main"
  }

  user_data = file("${path.module}/scripts/front.sh")
}

resource "aws_instance" "front_backup" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.my_ec2_type
  subnet_id                   = aws_subnet.public_subnet["10.10.10.32/27"].id
  key_name                    = var.my_key_pair
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true

  tags = {
    Name = "front_backup"
  }

  user_data = file("${path.module}/scripts/front.sh")
}

resource "aws_instance" "back_main" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.my_ec2_type
  subnet_id                   = aws_subnet.public_subnet["10.10.10.64/27"].id
  key_name                    = var.my_key_pair
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true

  tags = {
    Name = "back_main"
  }

}

resource "aws_instance" "back_backup" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.my_ec2_type
  subnet_id                   = aws_subnet.public_subnet["10.10.10.96/27"].id
  key_name                    = var.my_key_pair
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true

  tags = {
    Name = "back_backup"
  }

}

resource "null_resource" "back_main" {
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${path.module}/${var.my_key_pair}.pem")
    host        = aws_instance.back_main.public_ip
  }

  provisioner "file" {
    source      = "scripts/back.sh"
    destination = "/tmp/back.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "export HOSTNAME=${aws_instance.back_main.public_dns}",
      "sudo bash /tmp/back.sh",
    ]
  }
}

resource "null_resource" "back_backup" {
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${path.module}/${var.my_key_pair}.pem")
    host        = aws_instance.back_backup.public_ip
  }

  provisioner "file" {
    source      = "scripts/back.sh"
    destination = "/tmp/back.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "export HOSTNAME=${aws_instance.back_backup.public_dns}",
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