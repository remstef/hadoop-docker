#!/usr/bin/env bash
set -e 

env | grep -v "^HOME=" | grep -v "^TERM=" | grep -v "^PWD=" | sudo bash -c 'cat - > /opt/home-sshuser/.ssh/environment'
env | grep -v "^HOME=" | grep -v "^TERM=" | grep -v "^PWD=" | sudo bash -c 'cat - > /etc/environment'
sudo bash -c "echo \"sshuser:${SSH_USER_PASSWORD}\" | chpasswd "

sudo /usr/sbin/sshd -D
