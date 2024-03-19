import os
import subprocess
import boto3

def run_terraform_command(command):
    try:
        result = subprocess.run(command, shell=True, check=True, text=True, capture_output=True)
        print(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")
        print(e.stderr)

# Get user input for VPC details
vpc_name = input("Enter the name of VPC: ")
vpc_cidr_block = input("Enter the CIDR block of VPC (e.g., 10.0.0.0/16): ")

# Get user input for pub subnet details
pub_cidr = []
pub_az = []
pub_sub_count = int(input("Enter the no of public subnets : "))
for i in range(pub_sub_count):
    cidr_block = input(f"Enter the CIDR block for public subnet {i + 1} (e.g., 10.0.{i + 1}.0/24): ")
    az = input(f"Enter the availability zone for public subnet {i + 1} (e.g., us-east-2b): ")
    pub_cidr.append(cidr_block)
    pub_az.append(az)
pub_cidr_string = ', '.join([f'"{item}"' for item in pub_cidr])
pub_az_string = ', '.join([f'"{item}"' for item in pub_az])

# Get user input for pri subnet details
pri_cidr = []
pri_az = []
pri_sub_count = int(input("Enter the no of private subnets : "))
for i in range(pri_sub_count):
    cidr_block = input(f"Enter the CIDR block for private subnet {i + 1} (e.g., 10.0.{i + 1}.0/24): ")
    az = input(f"Enter the availability zone for private subnet {i + 1} (e.g., us-east-2b): ")
    pri_cidr.append(cidr_block)
    pri_az.append(az)
pri_cidr_string = ', '.join([f'"{item}"' for item in pri_cidr])
pri_az_string = ', '.join([f'"{item}"' for item in pri_az])

# Create key pair using boto3
#path_key_pem = "/project/terra/chatapp-key-pair.pem"
#ec2 = boto3.client('ec2')
# Create key pair
#key_pair = ec2.create_key_pair(KeyName='chatapp-key-pair')

# Save private key to a file
#with open('/project/terra/chatapp-key-pair.pem', 'w') as f:
#    f.write(key_pair['KeyMaterial'])

#if os.path.exists(path_key_pem):
#    print ()
#    print ("Key Is created")

# Specify the new variables.tf content
variables_content = f'''
variable "vpc_name" {{
    description = "Enter the name of VPC"
    type        = string
    default     = "{vpc_name}"
}}

variable "vpc_cidr_block" {{
    description = "Enter the CIDR of VPC"
    type        = string
    default     = "{vpc_cidr_block}"
}}

variable "pub_sub_count" {{
    description = "Enter no of public subnet count"
    type        = number
    default     = "{pub_sub_count}"
}}

variable "pub_sub_cidr" {{
    description = "CIDR of Pub subnets"
    type        = list(string)
    default = [{pub_cidr_string}]
}}

variable "pub_sub_az" {{
    description = "AZ of Pub subnets"
    type        = list(string)
    default = [{pub_az_string}]

}}

variable "pri_sub_count" {{
    description = "Enter no of private subnet count"
    type        = number
    default     = "{pri_sub_count}"
}}

variable "pri_sub_cidr" {{
    description = "CIDR of Pri subnets"
    type        = list(string)
    default = [{pri_cidr_string}]
}}

variable "pri_sub_az" {{
    description = "AZ of Pri subnets"
    type        = list(string)
    default = [{pri_az_string}]

}}

variable "identifer" {{
    description = "Indentifier of db instance"
    type        = string
    default     = "mydbinstance"
}}

variable "db_username" {{
    description = "Username of DataBase"
    type        = string
    default     = "admin"
}}

variable "db_password" {{
    description = "Password of DataBase"
    type        = string
    default     = "Supriyo12"
}}
'''

# Specify the path to variables.tf
variables_file_path = "/project/terraform_new/variables.tf"

# Check if variables.tf exists
if os.path.exists(variables_file_path):
    # Clear the content if the file exists
    with open(variables_file_path, "w") as variables_file:
        variables_file.write("")
    with open(variables_file_path, "w") as variables_file:
        variables_file.write(variables_content)
else:
    # Create the file if it doesn't exist
    with open(variables_file_path, "w") as variables_file:
        variables_file.write(variables_content)

# Write the new content to variables.tf
#with open(variables_file_path, "w") as variables_file:
#    variables_file.write(variables_content)

# Specify your Terraform command
terraform_command = "terraform init && terraform apply -auto-approve"

# Run the Terraform command
run_terraform_command(terraform_command)

