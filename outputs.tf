output "subnet_id" {
  value = aws_subnet.training[0].id
}

output "security_group_id" {
  value = aws_security_group.training.id
}

output "ami_id" {
  value = data.aws_ami.ubuntu.image_id
}