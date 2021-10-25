#!/bin/bash
touch /etc/ecs/ecs.config
cat <<EOT > /etc/ecs/ecs.config
ECS_ENABLE_TASK_IAM_ROLE=true
ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true
ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","awslogs"]
ECS_LOGLEVEL=debug
ECS_CLUSTER=mfa-ecs
EOT
yum install -y awslogs
mv /etc/awslogs/awslogs.conf /etc/awslogs/awslogs.conf.bak
touch /etc/awslogs/awslogs.conf
cat <<EOT > /etc/awslogs/awslogs.conf
[general]
state_file = /var/lib/awslogs/agent-state
[/var/log/dmesg]
file = /var/log/dmesg
log_group_name = mfa-ECS-OS-dmesg
log_stream_name = {instance_id}
[/var/log/messages]
file = /var/log/messages
log_group_name = mfa-ECS-OS-messages
log_stream_name = {instance_id}
datetime_format = %b %d %H:%M:%S
[/var/log/ecs/ecs-init.log]
file = /var/log/ecs/ecs-init.log
log_group_name = mfa-ECS-OS-ecs-init.log
log_stream_name = {instance_id}
datetime_format = %Y-%m-%dT%H:%M:%SZ
[/var/log/ecs/ecs-agent.log]
file = /var/log/ecs/ecs-agent.log
log_group_name = mfa-ECS-OS-ecs-agent.log
log_stream_name = {instance_id}
datetime_format = %Y-%m-%dT%H:%M:%SZ
EOT
sed -i -e "s/us-east-1/sa-east-1/g" /etc/awslogs/awscli.conf
systemctl start awslogsd
systemctl enable awslogsd
/bin/easy_install --script-dir /opt/aws/bin https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz
/opt/aws/bin/cfn-signal -e $? --stack mfa-ecs --resource ECSAutoScalingGroup --region sa-east-1
