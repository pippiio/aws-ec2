#!/bin/bash

# Add trusted ssh keys 
%{ for ssh_key in ssh_keys ~}
echo ${ssh_key} >> ~ec2-user/.ssh/authorized_keys
%{ endfor ~}

# Mount volumes
%{ for volume in volumes ~}
device=$(realpath ${volume.device_name})
mkfs -t xfs $device
mkdir -p ${volume.mountpoint}
mount $device ${volume.mountpoint}

%{ endfor ~}
# Volumes mounted

# Update packages
yum update -y

# Install and configre cloudwatch log agent
yum install -y awslogs

cat << EOT > /etc/awslogs/awscli.conf
[plugins]
cwlogs=cwlogs
[default]
region=${aws_region}
EOT

cat << EOT > /etc/awslogs/awslogs.conf
[general]
state_file = /var/lib/awslogs/agent-state
log_group_name=${log_group}
log_stream_name=log_stream_name = {instance_id}

[/var/log/messages]
file = /var/log/messages
datetime_format=%b %d %H:%M:%S
log_group_name=${log_group}
log_stream_name = {instance_id}/var/log/messages

[/var/log/cloud-init.log]
file=/var/log/cloud-init.log
datetime_format=%b %d %H:%M:%S
log_group_name=${log_group}
log_stream_name={instance_id}/var/log/cloud-init.log

[/var/log/cloud-init-output.log]
file=/var/log/cloud-init-output.log
datetime_format=
log_group_name=${log_group}
log_stream_name={instance_id}/var/log/cloud-init-output.log

%{ for logfile in logfiles ~}
[${logfile.path}]
file=${logfile.path}
log_group_name=${log_group}
log_stream_name={instance_id}${logfile.path}
datetime_format=${logfile.datetime_format}
%{ endfor ~}
EOT

systemctl start awslogsd
systemctl enable awslogsd.service

# Install docker
sudo amazon-linux-extras install docker
sudo service docker start
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# Install docker compose
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /bin/docker-compose
sudo chmod +x /bin/docker-compose

%{ for command in commands ~}
${command}
%{ endfor ~}
