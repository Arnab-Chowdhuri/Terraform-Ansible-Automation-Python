
variable "vpc_name" {
    description = "Enter the name of VPC"
    type        = string
    default     = "arnab_tf_vpc"
}

variable "vpc_cidr_block" {
    description = "Enter the CIDR of VPC"
    type        = string
    default     = "10.0.0.0/16"
}

variable "pub_sub_count" {
    description = "Enter no of public subnet count"
    type        = number
    default     = "2"
}

variable "pub_sub_cidr" {
    description = "CIDR of Pub subnets"
    type        = list(string)
    default = ["10.0.6.0/24", "10.0.7.0/24"]
}

variable "pub_sub_az" {
    description = "AZ of Pub subnets"
    type        = list(string)
    default = ["us-east-2a", "us-east-2b"]

}

variable "pri_sub_count" {
    description = "Enter no of private subnet count"
    type        = number
    default     = "2"
}

variable "pri_sub_cidr" {
    description = "CIDR of Pri subnets"
    type        = list(string)
    default = ["10.0.8.0/24", "10.0.9.0/24"]
}

variable "pri_sub_az" {
    description = "AZ of Pri subnets"
    type        = list(string)
    default = ["us-east-2a", "us-east-2b"]

}

variable "identifer" {
    description = "Indentifier of db instance"
    type        = string
    default     = "mydbinstance"
}

variable "db_username" {
    description = "Username of DataBase"
    type        = string
    default     = "admin"
}

variable "db_password" {
    description = "Password of DataBase"
    type        = string
    default     = "Supriyo12"
}
