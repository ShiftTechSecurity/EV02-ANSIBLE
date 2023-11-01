#!/bin/bash
# Création de l'utilisateur local "ansible"
sudo useradd -d /home/ansible -s /bin/bash ansible
passwd ansible

# Création d'un répertoire pour le stockage des sauvegardes cisco
mkdir -p /home/ansible/cisco/{image,config}

# Configuration de l'utilisateur "ansible" pour l'utilisation de proftpd
sed -i 's/User proftpd/User ansible/' /etc/proftpd/proftpd.conf
sed -i 's/Group nogroup/Group ansible/' /etc/proftpd/proftpd.conf
sed -i 's/# DefaultRoot ~/DefaultRoot \/home\/ansible\/cisco ansible/' /etc/proftpd/proftpd.conf