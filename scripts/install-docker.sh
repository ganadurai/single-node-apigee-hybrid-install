#!/bin/bash

set -e

function installDocker() {
  sudo apt-get update
  sudo apt install --yes apt-transport-https ca-certificates curl gnupg2 software-properties-common
  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
  echo "Waiting for 10s..."
  sleep 10
  sudo apt-get update
  sudo apt install --yes docker-ce
}

installDocker;
sudo usermod -aG docker "$USER"
printf "\n\n\nPlease close the session and reopen for docker install to be completed !!\n\n"
