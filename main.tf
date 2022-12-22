data "aws_vpc" "mum-default-vpc" {
  default = true
}

data "aws_subnets" "mum-default-subnets" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.mum-default-vpc.id]
  }
}

provider "aws" {
    region = "ap-south-1"      
}

/*
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
*/
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

resource "aws_launch_configuration" "fawaz-webserver-lc" {
  image_id = "ami-07ffb2f4d65357b42"
  instance_type = "t2.micro"
  security_groups = [ aws_security_group.tf-upnr-fawaz-sg.id ]
  user_data = <<-EOF
    #!/usr/bin/bash
    echo "Hello World from Fawaz" > index.html
    nohup busybox httpd -f -p ${var.webserver-port} &
  EOF

  lifecycle {
    create_before_destroy = true
  }  
  
}

resource "aws_autoscaling_group" "fawaz-asg" {
  launch_configuration = aws_launch_configuration.fawaz-webserver-lc.name
  vpc_zone_identifier = data.aws_subnets.mum-default-subnets.ids

  min_size = 1
  max_size = 2

  tag {
    key = "Name"
    value = "fawaz-terraform-eg-asg"
    propagate_at_launch = true
  }
  
}

/*
output "tf-upnr-webserver-ip" {
  value = aws_instance.example.public_dns
}
*/
