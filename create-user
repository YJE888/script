#!/bin/bash

# Get parameter
if ([ $# == 0 ]) || ([ $# -eq 1 ] && [ "$1" == "-h" -o "$1" == "--help" ]); then
  echo "create-user <user>"
  echo " user: username"
  echo "MUST RUN as root user or sudo's user."
  exit 1
fi

user=$1

grep ${user} /etc/passwd 2>/dev/null
if [ $? -eq 0 ]; then
  echo "${user} is already exists"
else
  sudo useradd ${user}
  sudo passwd ${user}
  sudo usermod -aG docker ${user}
fi

# cp kubeconfig
sudo mkdir -p /home/${user}/.kube
sudo cp ~/.kube/config /home/${user}/.kube/
sudo cp ~/.kube/setup-config /home/${user}/.kube/
sudo chown -R ${user}:${user} /home/${user}/.kube

echo "${user} is created successfully!"

exit 0
