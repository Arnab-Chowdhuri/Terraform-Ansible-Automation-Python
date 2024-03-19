output "Ansible_Server_public_ip" {
  value = aws_instance.Ansible_instance.public_ip
}

output "FrontEnd_private_ip" {
  value = aws_instance.FE_instance.private_ip
}

output "FrontEnd_public_ip" {
  value = aws_instance.FE_instance.public_ip
}

output "BackEnd_private_ip" {
  value = aws_instance.BE_instance.private_ip
}

output "RDS_HOST" {
  value = split(":", aws_db_instance.myDBInstance.endpoint)[0]
}
