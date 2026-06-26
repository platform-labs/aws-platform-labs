# Temporary EC2 instance used only to verify the network in this lab:
#   - SSH reachable from my IP (public subnet + IGW route)
#   - curl/ping out to the internet (public subnet + IGW route)
# After verification, this resource block can simply be removed (or
# `terraform destroy -target` it) - it is not part of the platform foundation
# that Lab 4 will build on.
#
# NOTE: this does NOT replace or touch the EC2 instance from Lab 1
# (Generation 1, default VPC). This is a brand-new, throwaway instance.

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "network_test" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.test_ec2_instance_type
  subnet_id              = aws_subnet.public[0].id
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.test_ec2.id]

  tags = {
    Name    = "${var.project_name}-network-test-ec2"
    Purpose = "Lab 3 verification only - safe to terminate after checks pass"
  }
}
