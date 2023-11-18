
# DEFINING APPLICATION SERVER SECUTIRY GROUP ALLOWING ACCES FRON ALB ONLY

resource "aws_security_group" "app_server_sg" {
  name        = "${var.ProjectName}-${var.env}-app-server-sg"
  description = "SG of App Server"
  vpc_id      = data.aws_vpc.CloudGuru.id


  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.alb_sg.id}"]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.ProjectName}-${var.env}-app_server_sg",
    },
  )
}


# DEFINING ALB SECURITY GROUP

resource "aws_security_group" "alb_sg" {
  name        = "${var.ProjectName}-${var.env}-alb-sg"
  description = "SG of ALB"
  vpc_id      = data.aws_vpc.CloudGuru.id

  ingress {
    description      = "HTTP Access from Anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] 
    ipv6_cidr_blocks = ["::/0"]      
  }

  ingress {
    description      = "HTTP Access from Anywhere"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"] 
    ipv6_cidr_blocks = ["::/0"]      
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.ProjectName}-${var.env}-alb_sg",
    },
  )
}

