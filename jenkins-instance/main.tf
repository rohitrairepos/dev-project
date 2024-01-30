terraform {

  backend "s3" {
    bucket = "terrafrom-dj"
    key    = "devopsdj.tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}


resource "aws_security_group" "aws_sg" {
  name = "security group from terraform"

  ingress {
    description = "SSH from the internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "80 from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "8080 from the internet"
    from_port   = 8080
    to_port     = 8080
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

resource "aws_instance" "aws_ins_web" {

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = local.instance_size
  vpc_security_group_ids      = [aws_security_group.aws_sg.id]
  associate_public_ip_address = true
  #key_name                    = "aws-ec2" # your key here
  key_name = aws_key_pair.deployer.key_name
  /*connection {
    
    type = "ssh"
    host = self.public_ip
    user = "ubuntu"
    private_key = var.private_key
    timeout = "4m"
  }
*/
  tags = {
    Name = "Jenkis-server"
  }

}

resource "aws_key_pair" "deployer" {
    key_name = var.key_name
    public_key = var.public_key
  
}

# an empty resource block
resource "null_resource" "jenkins_config" {

  # ssh into the ec2 instance 
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = var.private_key
    host        = aws_instance.aws_ins_web.public_ip
  }

  # copy the install_jenkins.sh file from your computer to the ec2 instance 
  provisioner "file" {
    source      = "install_jenkins.sh"
    destination = "/tmp/install_jenkins.sh"
  }

  # set permissions and run the install_jenkins.sh file
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/install_jenkins.sh",
      "sh /tmp/install_jenkins.sh",
    ]
  }

  # wait for ec2 to be created
  depends_on = [aws_instance.aws_ins_web]
}

output "instance_ip" {
  value = aws_instance.aws_ins_web.public_ip
}

# output.tf
# print the url of the jenkins server
output "website_url" {
  value = join("", ["http://", aws_instance.aws_ins_web.public_dns, ":", "8080"])
}
