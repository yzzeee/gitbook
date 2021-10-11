output "wp_ip" {
  description = "elastic ip of instance"
  value       = aws_eip.wp_eip.public_ip
}
