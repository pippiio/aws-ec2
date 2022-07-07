#!/bin/bash

sudo yum update -y

# Add trusted ssh keys 
%{ for ssh_key in ssh_keys ~}
echo ${ssh_key} >> ~ec2-user/.ssh/authorized_keys
%{ endfor ~}

# Install docker image
sudo amazon-linux-extras install docker
sudo service docker start
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

%{ for command in commands ~}
${command}
%{ endfor ~}
