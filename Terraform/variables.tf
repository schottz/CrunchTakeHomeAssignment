variable db_username {
  default = "root"
  type        = string
}

variable availability_zones {
  default = ["sa-east-1a", "sa-east-1b", "sa-east-1c"]
}

variable public_subnet_cidr_blocks {
  default = {
    sa-east-1a = "10.0.20.0/24"
    sa-east-1b = "10.0.21.0/24"
    sa-east-1c = "10.0.22.0/24"
  }
}

variable private_subnet_cidr_blocks {
  default = {
    sa-east-1a = "10.0.1.0/24"
    sa-east-1b = "10.0.2.0/24"
    sa-east-1c = "10.0.3.0/24"
  }
}

variable region {
  default = "sa-east-1"
}

variable db_port {
    default = "5432"
}

variable db_instance_name {
    default = "boilerplate"
}

variable applicatio_port {
    default = "4000"
}