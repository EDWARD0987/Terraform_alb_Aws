provider "aws" {
  region = var.aws_region
}


# DEFINING APPLICATION SERVER
resource "aws_instance" "app_server_ec2" {
  ami                    = "ami-067d1e60475437da2" # data.aws_ami.amazon_linux.id
  instance_type          = var.app_server_instance_type
  subnet_id              = var.subnet_id
  monitoring             = false
  vpc_security_group_ids = [aws_security_group.app_server_sg.id]
  #user_data              = filebase64("user_data.sh")
  iam_instance_profile   = data.aws_iam_instance_profile.ssm_role.role_name # Attach role created in var.tf here for role to populate on ec2


  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.ProjectName}-${var.env}-ec2",
    },
  )
}



# DEFINING ALB 
resource "aws_lb" "alb" {
  name               = "${var.ProjectName}-${var.env}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = ["subnet-031413dc70965a163", "subnet-038fc6a3e7ef68131"] 




  enable_deletion_protection = false
  drop_invalid_header_fields = true

  #   access_logs {                                           # TODO will create later
  #     bucket  = aws_s3_bucket.alb-logs.bucket
  #     prefix  = "${var.ProjectName}-alb"
  #     enabled = true
  #   }

  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.ProjectName}-${var.env}-alb",
    },
  )
}



# ALB LISTENER
resource "aws_lb_listener" "public-proxy" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"



  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public-proxy.arn # Name of TARGET GROUP RESOURCE 
  }
}



# ALB TARGET GROUP
resource "aws_lb_target_group" "public-proxy" {
  name     = "${var.env}-public-proxy"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.CloudGuru.id 





  health_check {
    port                = 80
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    matcher             = "200-499"
    path                = "/"
  }

  tags = merge(
    local.common_tags,
    {
      "Name" = "${var.ProjectName}-${var.env}-public-proxy",
    },
  )
}

resource "aws_lb_target_group_attachment" "tg_attachment" {
  target_group_arn = aws_lb_target_group.public-proxy.arn
  # attach the ALB to this target group     
  target_id = aws_instance.app_server_ec2.id #aws_lb.alb.arn
  #  If the target type is alb, the targeted Application Load Balancer must have at least one listener whose port matches the target group port.
  port = 80

}



# DEFINING LAUNCH TEMPLATE
resource "aws_launch_template" "aols-spa-lt" {

  name_prefix            = "${var.ProjectName}-${var.env}-lt"
  description            = "launch template for aols-spa frontend"
  image_id               = "ami-067d1e60475437da2"
  instance_type          = var.app_server_instance_type
  vpc_security_group_ids = [aws_security_group.app_server_sg.id]
  user_data              = filebase64("user_data.sh")

  update_default_version = true

}



# # DEFINING AUTO SCALING GROUP
# resource "aws_autoscaling_group" "aols-spa-asg" {
#   availability_zones = ["us-east-1a","us-east-1b"]
#   depends_on = [ aws_launch_template.aols-spa-lt ]
#   desired_capacity   = 1
#   max_size           = 2
#   min_size           = 1
#   target_group_arns = [aws_lb_target_group.public-proxy.arn]







#   launch_template {
#     id      = aws_launch_template.aols-spa-lt.id
#     version = "$Latest"
#   }
# }