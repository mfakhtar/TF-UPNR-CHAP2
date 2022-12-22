provider "aws" {
    region = "ap-south-1"      
}

resource "aws_instance" "example" {
    ami = "ami-07ffb2f4d65357b42"
    instance_type = "t2.micro"

    user_data = <<-EOF
    #!/bin/bash
    echo "Hello World from Fawaz" > index.html
    noup busybox httpd -f -p 8080 &
    EOF

  user_data_replace_on_change = true

    tags = {
      Name = "fawaz-terraform-eg"
    }
}

resource "aws_security_group" "tf-upnr-fawaz-sg" {
    name = "tf-upnr-fawaz-sg"

    ingress {
      from_port = "8080"
      to_port = "8080"
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
}
