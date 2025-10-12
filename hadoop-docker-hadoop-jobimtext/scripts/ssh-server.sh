#!/usr/bin/env bash
set -e 

env | grep -v "^HOME=" | grep -v "^TERM=" | grep -v "^PWD=" | sudo bash -c 'cat - > /opt/hadoop/.ssh/environment'

sudo /usr/sbin/sshd -D
