#!/bin/bash
sudo amazon-linux-extras install ansible2 -y
sudo yum install git -y
ansible-pull -U https://github.com/c1t1d0s7/ansible-pull-example.git -C main -i hosts.ini playbook.yaml
