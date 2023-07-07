provider "aws" {
    region = "eu-west-1"
}

module "asg" {
  //source = "../../cluster/asg-rolling-deploy"
    source = "github.com/KazikKluz/terrabook-modules//cluster/asg-rolling-deploy?ref=v0.0.9"

  cluster_name = "hello-world-${var.environment}"
  ami = var.ami
  instance_type = var.instance_type

  user_data = templatefile("${path.module}/user-data.sh",{
    server_port = var.server_port
    db_address = local.mysql_config.db_address 
    db_port = local.mysql_config.db_port
    server_text = var.server_text
  })

  min_size = var.min_size
  max_size = var.max_size
  enable_autoscaling = var.enable_autoscaling

  subnet_ids = local.subnet_ids
  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  custom_tags = var.custom_tags
}

module "alb" {
  source = "../../../modules/networking/alb"

  alb_name = "hello-world-${var.environment}"
  subnet_ids = local.subnet_ids
}

resource "aws_lb_target_group" "asg" {
  name     = "hello-world-${var.environment}"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = local.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = module.alb.alb_http_listener_arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

locals {
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}



