locals {
  config = var.config

  ami = {
    amazon_linux_2 = {
      owner    = "amazon"
      name     = "amzn2-ami-hvm-*-x86_64-ebs"
      userdata = "amazon_linux.sh"
    }
    amazon_linux_ecs = {
      owner    = "amazon"
      name     = "amzn-ami-*-amazon-ecs-optimized"
      userdata = "amazon_linux.sh"
    }
    ubuntu = {
      owner    = "099720109477" # Canonical
      name     = "ubuntu/images/hvm-ssd/ubuntu*"
      userdata = "ubuntu.sh"
    }
  }

  enable_load_balancer = local.config.enable_load_balancer ? 1 : 0
}
