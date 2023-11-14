output "ec2_public_ip" {
  value = aws_instance.app_server_ec2.public_ip
}


output "dns_name" {
  description = "The dns name of the load balancer"
  value       = try(aws_lb.alb.dns_name, null)
}