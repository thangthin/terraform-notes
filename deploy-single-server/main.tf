# provider "aws" {
#     region = "us-east-1"
# }

# # general syntax for terraform resource
# # resource "PROVIDER_TYPE" "NAME" {
# #   [CONFIG ...]
# # }

# # In Terraform, every resource exposes attributes that you can access using interpolation
# # "${TYPE.NAME.ATTRIBUTE}"

# # The <<-EOF and EOF are Terraform’s heredoc syntax, which allows you to create multiline strings without having to insert newline characters all over the place.
# resource "aws_instance" "example" {
#     ami = "ami-009d6802948d06e52"
#     instance_type = "t2.micro"
#     vpc_security_group_ids = ["${aws_security_group.instance.id}"]
#     user_data = <<-EOF
#               #!/bin/bash
#               echo "Hello, World" > index.html
#               nohup busybox httpd -f -p 8080 &
#               EOF
    
#     tags = {
#         Name = "terraform-example"
#     }
# }

# # You need to do one more thing before this web server works. 
# # By default, AWS does not allow any incoming or outgoing traffic from an EC2 Instance. 
# # To allow the EC2 Instance to receive traffic on port 8080, you need to create a security group:
# resource "aws_security_group" "instance" {
#   name = "terraform-example-instance"

#   ingress {
#     from_port   = 8080
#     to_port     = 8080
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }
# # This code creates a new resource called aws_security_group (notice how all resources for the AWS provider start with aws_)
# #  and specifies that this group allows incoming TCP requests on port 8080 from the CIDR block 0.0.0.0/0. 
# # CIDR blocks are a concise way to specify IP address ranges. 
# # For example, a CIDR block of 10.0.0.0/24 represents all IP addresses between 10.0.0.0 and 10.0.0.255. 
# # The CIDR block 0.0.0.0/0 is an IP address range that includes all possible IP addresses, so this security group allows incoming requests on port 8080 from any IP.

# output "public_ip" {
#   value = "${aws_instance.example.public_ip}"
# }

provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "example" {
  ami                    = "ami-40d28157"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF

  tags {
    Name = "terraform-example"
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "public_ip" {
  value = "${aws_instance.example.public_ip}"
}
