provider "aws" {
    region = "ap-south-1"      
}

resource "aws_instance" "example" {
    ami = "ami-07ffb2f4d65357b42"
    instance_type = "t2.micro"
    vpc_security_group_ids = [ aws_security_group.tf-upnr-fawaz-sg.id ]
    key_name = "fawaz-tfe-guide"

    user_data = <<-EOF
    #!/usr/bin/bash
    echo "Hello World from Fawaz" > index.html
    nohup busybox httpd -f -p ${var.webserver-port} &
    EOF

  user_data_replace_on_change = true

    tags = {
      Name = "fawaz-terraform-eg"
    }
}

resource "aws_security_group" "tf-upnr-fawaz-sg" {
    name = "tf-upnr-fawaz-sg"

    ingress {
      from_port = var.webserver-port
      to_port = var.webserver-port
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
      from_port = "22"
      to_port = "22"
      protocol = "tcp"
      cidr_blocks = ["49.36.222.156/32"]
    }
}

output "tf-upnr-webserver-ip" {
  value = aws_instance.example.public_dns
}
