# Creating VPC
resource "aws_vpc" "My_VPC" {
  cidr_block       = var.vpc_cidr_block

  tags = {
    Name = var.vpc_name
  }
}

# Creating Public Subnets Using Var
resource "aws_subnet" "Public_Subnets" {
    vpc_id = aws_vpc.My_VPC.id
    count = var.pub_sub_count
    cidr_block = var.pub_sub_cidr[count.index]
    availability_zone = var.pub_sub_az[count.index]
    tags = {
      Name = "Public_Subnet_${count.index+1}_TF"
    }
}

# Creating Private Subnets Using Var
resource "aws_subnet" "Private_Subnets" {
    vpc_id = aws_vpc.My_VPC.id
    count = var.pri_sub_count
    cidr_block = var.pri_sub_cidr[count.index]
    availability_zone = var.pri_sub_az[count.index]
    tags = {
      Name = "Private_Subnet_${count.index+1}_TF"
    }
}

# Creating IGW in VPC
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.My_VPC.id

  tags = {
    Name = "IGW_Terraform"
  }
}

# elastic Ip for nat gateway
resource "aws_eip" "EIP" {
  domain = "vpc"
  tags = {
    Name = "EIP_TF"
  }
}

# Create NAT GW and attach it to Public subnet
resource "aws_nat_gateway" "NAT_GW" {
  allocation_id = aws_eip.EIP.id
  subnet_id     = aws_subnet.Public_Subnets[0].id

  tags = {
    Name = "NAT_GW_TF"
  }
}

#creating Public route table
resource "aws_route_table" "Public_RT" {
    vpc_id = aws_vpc.My_VPC.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.IGW.id
    }

    tags = {
        Name = "Pub_RT"
    }
}

#associating Public sub with Public route table
resource "aws_route_table_association" "Pub_RT_association" {
    count = length(aws_subnet.Public_Subnets)
    subnet_id = aws_subnet.Public_Subnets[count.index].id
    route_table_id = aws_route_table.Public_RT.id
}

#creating Private route table
resource "aws_route_table" "Private_RT" {
    vpc_id = aws_vpc.My_VPC.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.NAT_GW.id
    }

    tags = {
        Name = "Pri_RT"
    }
}

#associating private sub with private route table
resource "aws_route_table_association" "Pri_RT_association" {
    count = length(aws_subnet.Private_Subnets)
    subnet_id = aws_subnet.Private_Subnets[count.index].id
    route_table_id = aws_route_table.Private_RT.id
}

resource "aws_security_group" "SG_FE" {
  name   = "FE-sg"
  description = "Security Group for frontend-instance"
  vpc_id = aws_vpc.My_VPC.id
  tags = {
    Name = "SG-FE"
  }
  ingress{
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress{
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "SG_BE" {
  name   = "BE-sg"
  description = "Security Group for backend-instance"
  vpc_id = aws_vpc.My_VPC.id
  tags = {
    Name = "SG-BE"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress{
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress{
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#creating security groups for database
resource "aws_security_group" "databaseSecurityGroup" {
  name        = "database-security-group"
  description = "Security Group for database-instance"
  vpc_id      = aws_vpc.My_VPC.id
  tags = {
    Name = "database-security-group"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# To create a key pair
resource "tls_private_key" "rsa" {
        algorithm = "RSA"
        rsa_bits  = 4096
}

# Define the key pair resource
resource "aws_key_pair" "chatapp_key" {
        key_name   = "chatapp_key"
        public_key = tls_private_key.rsa.public_key_openssh
}

# Define the local file resource and Store the Private key in local
resource "local_file" "chatapp_key_local" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "/project/terraform_new/chatapp_key.pem"
}

# Use null_resource to change file permissions after creation
resource "null_resource" "change_file_permissions" {
  # Trigger execution whenever the local file is created or changed
  triggers = {
    local_file_content = local_file.chatapp_key_local.content
  }

  # Execute shell command to change file permissions
  provisioner "local-exec" {
    command = "chmod 400 /project/terraform_new/chatapp_key.pem"
  }
}

# # Creating FE Instance
resource "aws_instance" "FE_instance" {
    depends_on = [null_resource.change_file_permissions]
    ami                         = data.aws_ami.ubuntu_22_04.id
    instance_type               = "t2.micro"
    vpc_security_group_ids      = [aws_security_group.SG_FE.id]
    associate_public_ip_address = true
    key_name                    = aws_key_pair.chatapp_key.key_name
    subnet_id                   = aws_subnet.Public_Subnets[0].id
    tags = {
        Name = "FE_Instance"
    }
}

# Configure FE instance to add the line to the sudoers file
resource "null_resource" "configure_FE_instance" {
  depends_on = [
    null_resource.change_file_permissions,
    aws_instance.FE_instance
  ]
  # Define the SSH connection details for FE instance
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${local_file.chatapp_key_local.filename}")
    host        = "${aws_instance.FE_instance.public_ip}"
  }

  # Use file provisioner to copy the local key to the FE_instance
  provisioner "file" {
    source      = "${local_file.chatapp_key_local.filename}"
    destination = "/home/ubuntu/chatapp_key.pem"
  }
  # Use remote-exec provisioner to run commands on FE instance
  provisioner "remote-exec" {
    # Run the command to append the line to the sudoers file
    inline = [
#      "echo 'ubuntu ALL=(ALL:ALL) NOPASSWD: ALL' | sudo tee -a /etc/sudoers",
      "sudo chmod 400 /home/ubuntu/chatapp_key.pem",
#      "sudo useradd -m -s /bin/bash ansible",     # Create a new user
#      "echo 'ansible:1234' | sudo chpasswd",      # Set the password for the new user
#      "echo 'ansible ALL=(ALL:ALL) NOPASSWD: ALL' | sudo tee -a /etc/sudoers",
#      "echo 'PasswordAuthentication yes' | sudo tee -a /etc/ssh/sshd_config",
#      "echo 'PubkeyAuthentication yes' | sudo tee -a /etc/ssh/sshd_config",
#      "echo 'PermitRootLogin prohibit-password' | sudo tee -a /etc/ssh/sshd_config",
#      "sudo service ssh restart",  # Restart SSH service for changes to take effect
    ]
  }
}

# Use a separate null_resource block for file provisioner
#resource "null_resource" "copy_key_to_FE_instance" {
#  depends_on = [
#	null_resource.change_file_permissions,
#	aws_instance.FE_instance,
#	null_resource.configure_FE_instance
#  ]

  # Define the SSH connection details for FE instance
#  connection {
#    type        = "ssh"
#    user        = "ubuntu"
#    private_key = file("${local_file.chatapp_key_local.filename}")
#    host        = "${aws_instance.FE_instance.public_ip}"
#  }

  # Use file provisioner to copy the local key to the FE_instance
#  provisioner "file" {
#    source      = "${local_file.chatapp_key_local.filename}"
#    destination = "/home/ubuntu/chatapp_key.pem"
#  }
#}

# # Creating Ansible Instance
resource "aws_instance" "Ansible_instance" {
    depends_on = [null_resource.change_file_permissions]
    ami                         = data.aws_ami.ubuntu_22_04.id
    instance_type               = "t2.micro"
    vpc_security_group_ids      = [aws_security_group.SG_FE.id]
    associate_public_ip_address = true
    key_name                    = aws_key_pair.chatapp_key.key_name
    subnet_id                   = aws_subnet.Public_Subnets[0].id
    tags = {
        Name = "Ansible_Instance"
    }
}

# Configure instance Ansible to add the line to the sudoers file and install Ansible
resource "null_resource" "configure_Ansible_instance" {
  depends_on = [
	null_resource.change_file_permissions,
	aws_instance.Ansible_instance,
	aws_instance.BE_instance,
	aws_instance.FE_instance,
	aws_db_instance.myDBInstance,
  ]
  # Define the SSH connection details for instance Ansible, using the private key from the local file
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${local_file.chatapp_key_local.filename}")
    host        = "${aws_instance.Ansible_instance.public_ip}"
  }

  # Use file provisioner to copy the local key to the FE_instance
  provisioner "file" {
    source      = "${local_file.chatapp_key_local.filename}"
    destination = "/home/ubuntu/chatapp_key.pem"
  }

  # Use remote-exec provisioner to run commands on instance Ansible
  provisioner "remote-exec" {
    # Run the commands to update packages and install Ansible
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y software-properties-common",
      "sudo add-apt-repository --yes --update ppa:ansible/ansible",
      "sudo apt-get install -y ansible",
#      "sudo useradd -m -s /bin/bash ansible",     # Create a new user
#      "echo 'ansible:1234' | sudo chpasswd",      # Set the password for the new user
#      "echo 'ansible ALL=(ALL:ALL) NOPASSWD: ALL' | sudo tee -a /etc/sudoers",
#      "echo 'ubuntu ALL=(ALL:ALL) NOPASSWD: ALL' | sudo tee -a /etc/sudoers",
      "sudo chmod 400 /home/ubuntu/chatapp_key.pem",
#      "echo 'PasswordAuthentication yes' | sudo tee -a /etc/ssh/sshd_config",
#      "echo 'PubkeyAuthentication yes' | sudo tee -a /etc/ssh/sshd_config",
#      "echo 'PermitRootLogin prohibit-password' | sudo tee -a /etc/ssh/sshd_config",
#      "sudo service ssh restart",  # Restart SSH service for changes to take effect
      "ssh-keygen -t rsa -b 2048 -q -f /home/ubuntu/.ssh/id_rsa -N \"\"",
      "scp -o StrictHostKeyChecking=no -i /home/ubuntu/chatapp_key.pem /home/ubuntu/.ssh/id_rsa.pub ubuntu@${aws_instance.FE_instance.private_ip}:/tmp/id_rsa.pub",
#      "scp -i /home/ubuntu/chatapp_key.pem /home/ubuntu/.ssh/id_rsa.pub ubuntu@${aws_instance.FE_instance.private_ip}:/tmp/id_rsa.pub",
      "ssh -o StrictHostKeyChecking=no -i /home/ubuntu/chatapp_key.pem ubuntu@${aws_instance.FE_instance.private_ip} 'cat /tmp/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys'"
    ]
  }
  provisioner "remote-exec" {
    inline = [
      # Connect from Ansible instance to BE_instance
       "scp -o StrictHostKeyChecking=no -i /home/ubuntu/chatapp_key.pem /home/ubuntu/.ssh/id_rsa.pub ubuntu@${aws_instance.BE_instance.private_ip}:/tmp/id_rsa.pub",
       "ssh -o StrictHostKeyChecking=no -i /home/ubuntu/chatapp_key.pem ubuntu@${aws_instance.BE_instance.private_ip} 'cat /tmp/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys'"
#      "ssh -o StrictHostKeyChecking=no -i /home/ubuntu/chatapp_key.pem ubuntu@${aws_instance.BE_instance.private_ip} 'sudo useradd -m -s /bin/bash ansible'",
#      "ssh -o StrictHostKeyChecking=no -i /home/ubuntu/chatapp_key.pem ubuntu@${aws_instance.BE_instance.private_ip} 'echo \"ansible:1234\" | sudo chpasswd'",
#      "ssh -o StrictHostKeyChecking=no -i /home/ubuntu/chatapp_key.pem ubuntu@${aws_instance.BE_instance.private_ip} 'echo \"ansible ALL=(ALL:ALL) NOPASSWD: ALL\" | sudo tee -a /etc/sudoers'",
#      "ssh -o StrictHostKeyChecking=no -i /home/ubuntu/chatapp_key.pem ubuntu@${aws_instance.BE_instance.private_ip} 'echo \"ubuntu ALL=(ALL:ALL) NOPASSWD: ALL\" | sudo tee -a /etc/sudoers'",
#      "ssh -o StrictHostKeyChecking=no -i /home/ubuntu/chatapp_key.pem ubuntu@${aws_instance.BE_instance.private_ip} 'sudo sed -i \"/PasswordAuthentication/c\\PasswordAuthentication yes\" /etc/ssh/sshd_config'",
#      "ssh -o StrictHostKeyChecking=no -i /home/ubuntu/chatapp_key.pem ubuntu@${aws_instance.BE_instance.private_ip} 'echo \"PubkeyAuthentication yes\" | sudo tee -a /etc/ssh/sshd_config'",
#      "ssh -o StrictHostKeyChecking=no -i /home/ubuntu/chatapp_key.pem ubuntu@${aws_instance.BE_instance.private_ip} 'echo \"PermitRootLogin prohibit-password\" | sudo tee -a /etc/ssh/sshd_config'",
#      "ssh -o StrictHostKeyChecking=no -i /home/ubuntu/chatapp_key.pem ubuntu@${aws_instance.BE_instance.private_ip} 'sudo service ssh restart'",
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "git clone 'https://github.com/Arnab-Chowdhuri/Ansible-Project.git'",
      "cat <<EOF > Ansible-Project/My_3tire_playbook/inventory",
      "[frontend]",
      "${aws_instance.FE_instance.private_ip}",
      "[backend]",
      "${aws_instance.BE_instance.private_ip}",
      "EOF",
      "echo 'proxy_pass_BE: ${aws_instance.BE_instance.private_ip}' > Ansible-Project/My_3tire_playbook/roles/frontend_server/vars/main.yml",
      "echo 'db_name: ${aws_db_instance.myDBInstance.db_name}' >> Ansible-Project/My_3tire_playbook/roles/backend_server/vars/main.yml",
      "echo 'db_password: ${var.db_password}' >> Ansible-Project/My_3tire_playbook/roles/backend_server/vars/main.yml",
      "echo 'db_host: ${split(":", aws_db_instance.myDBInstance.endpoint)[0]}' >> Ansible-Project/My_3tire_playbook/roles/backend_server/vars/main.yml",
      "echo 'user_name: ${var.db_username}' >> Ansible-Project/My_3tire_playbook/roles/backend_server/vars/main.yml",
    ]
  }
}

# Run Ansible Playbook using Terraform remote-exec

resource "null_resource" "Run_Ansible_Playbook" {
  depends_on = [
        null_resource.change_file_permissions,
        aws_instance.Ansible_instance,
        aws_instance.BE_instance,
        aws_instance.FE_instance,
        aws_db_instance.myDBInstance,
	null_resource.configure_Ansible_instance,
	null_resource.configure_FE_instance,
  ]
  # Define the SSH connection details for instance Ansible, using the private key from the local file
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${local_file.chatapp_key_local.filename}")
    host        = "${aws_instance.Ansible_instance.public_ip}"
  }

  # Use remote-exec provisioner to run commands on instance Ansible
  provisioner "remote-exec" {
    # Run the commands to update packages and install Ansible
    inline = [
      "ansible-playbook -i Ansible-Project/My_3tire_playbook/inventory Ansible-Project/My_3tire_playbook/master.yml",
    ]
  }
}

  # Use a separate remote-exec provisioner to restart the SSH service
#  provisioner "remote-exec" {
#    inline = [
#      "sudo service ssh restart"  # Restart SSH service for changes to take effect
#    ]
#  }


# # Creating BE Instance
resource "aws_instance" "BE_instance" {
    depends_on = [null_resource.change_file_permissions]
    ami                         = data.aws_ami.BE_AMI.id
    instance_type               = "t2.micro"
    vpc_security_group_ids      = [aws_security_group.SG_BE.id]
    associate_public_ip_address = false
    key_name                    = aws_key_pair.chatapp_key.key_name
    subnet_id                   = aws_subnet.Private_Subnets[0].id
    tags = {
        Name = "BE_Instance"
    }
}


# Output the content of the .pem file for the key pair
#output "keypair_pem_content" {
#  value = aws_key_pair.example_keypair.private_key_pem
#}

#creating subnet groups for the db instance
resource "aws_db_subnet_group" "mySubnetGroup1" {
  name       = "my-subnet-group-1"
  subnet_ids = [for subnet in aws_subnet.Private_Subnets : subnet.id]
  tags = {
    Name = "mySubnetGroup-1"
  }
}

#creating DB-instance
resource "aws_db_instance" "myDBInstance" {
  allocated_storage      = 20
  db_name                = "myDbInstance"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  db_subnet_group_name   = aws_db_subnet_group.mySubnetGroup1.name
  multi_az               = false
  vpc_security_group_ids = [aws_security_group.databaseSecurityGroup.id]
  username               = var.db_username
  password               = var.db_password
  skip_final_snapshot    = true
  tags = {
    Name = "my-db-instance"
  }
}
