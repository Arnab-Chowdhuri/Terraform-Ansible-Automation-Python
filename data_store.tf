#data "aws_ami" "FE_AMI" {
#    owners      = ["905418436056"]  # Replace with the AWS account ID where the AMI is located
#    
#    filter {
#        name   = "name"
#        values = ["FE-Image"]
#    }
#  
#}
#
#data "aws_ami" "BE_AMI" {
#    owners      = ["905418436056"]  # Replace with the AWS account ID where the AMI is located
#   
#    filter {
#        name   = "name"
#        values = ["BE-Image"]
#    }
#  
#}

data "aws_ami" "ubuntu_22_04" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20240207.1"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical owner ID
}

data "aws_ami" "BE_AMI" {
    owners      = ["905418436056"]  # Replace with the AWS account ID where the AMI is located

    filter {
        name   = "name"
        values = ["Bansir_AMI_ubuntu_18.04"]
    }

}
