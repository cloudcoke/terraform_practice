data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20230517"]
  }
}

resource "aws_instance" "front" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet["10.10.10.0/27"].id
  key_name                    = "my-ec2-keypair"
  vpc_security_group_ids      = [aws_security_group.default_security_group.id]
  associate_public_ip_address = true

  tags = {
    Name = "front-server"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${path.module}/my-ec2-keypair.pem")
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "scripts/front.sh"
    destination = "/tmp/front.sh"

  }

  provisioner "remote-exec" {
    inline = [
      "sudo bash /tmp/front.sh"
    ]
  }
}