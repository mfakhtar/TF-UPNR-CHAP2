data "aws_vpc" "mum-default-vpc" {
  default = true
}

data "aws_subnets" "mum-default-subnets" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.mum-default-vpc.id]

  }
    filter {
    name   = "default-for-az"
    values = [true]
  }
  filter {
    name   = "state"
    values = ["available"]
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

  target_group_arns = [ aws_lb_target_group.asg-target.arn ]
  health_check_type = "ELB"

  min_size = 1
  max_size = 2

  tag {
    key = "Name"
    value = "fawaz-terraform-eg-asg"
    propagate_at_launch = true
  }
  
}

resource "aws_lb" "fawaz-asg-lb" {
  name = "fawaz-asg-lb"
  load_balancer_type = "application"
  subnets = data.aws_subnets.mum-default-subnets.ids
  security_groups = [ aws_security_group.tf-upnr-fawaz-asg-lb.id ]
}

resource "aws_lb_listener" "fawaz-asg-lb-listner" {
  load_balancer_arn = aws_lb.fawaz-asg-lb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "fixed-response"      

  fixed_response {
    content_type = "text/plain"
    message_body = "404: page not found"
    status_code  = 404
    }
  }
}

resource "aws_security_group" "tf-upnr-fawaz-asg-lb" {
    name = "tf-upnr-fawaz-asg-lb"
    
    ingress {
      from_port = "80"
      to_port = "80"
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

resource "aws_lb_target_group" "asg-target" {
  name = "asg-target"
  port = var.webserver-port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.mum-default-vpc.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
  
}

resource "aws_lb_listener_rule" "lb-asg-listner-rule" {
  listener_arn = aws_lb_listener.fawaz-asg-lb-listner.arn
  priority = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg-target.arn
  }
  
}


output "tf-upnr-webserver-dns" {
  value = aws_lb.fawaz-asg-lb.dns_name
}
