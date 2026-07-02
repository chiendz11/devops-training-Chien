output "public_ip" {
  description = "Elastic public IP of the EC2 instance"
  value       = aws_eip.web.public_ip
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web.id
}

output "website_url" {
  description = "HTTP URL"
  value       = "http://${aws_eip.web.public_ip}"
}
