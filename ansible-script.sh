#!/bin/bash
# Installation des outils : sudo, man, tree, net-tools, curl, et pip
apt update -y && apt upgrade -y
apt install sudo man tree net-tools curl pip -y

# Installation de Ansible, et la dépendance sshpass
apt install ansible sshpass -y

# Installation du plugin ansible "cisco.ios" pour équipements réseau
ansible-galaxy collection install cisco.ios

# Installation de paramiko, une dépendances des modules "cisco.ios"
apt install python3-paramiko -y

# Création utilisateur local "ansible" et ajout aux utilisateurs "NO PASSWORD" de sudo
sudo useradd -d /home/ansible -s /bin/bash ansible
passwd ansible
echo 'ansible ALL=(ALL) NOPASSWD: ALL' | tee -a /etc/sudoers

# Génération d'un fichier de configuration pour le service ssh pour l'utilisateur ansible nécessaire pour la communication avec les équipements cisco "Legacy"
mkdir -p /home/ansible/.ssh
echo "KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,diffie-hellman-group-exchange-sha256,diffie-hellman-group14-sha1,diffie-hellman-group1-sha1,diffie-hellman-group14-sha256" > /home/ansible/.ssh/config
echo -e "Host *\n  PubkeyAcceptedKeyTypes=+ssh-rsa\n  HostKeyAlgorithms=+ssh-rsa\n  Ciphers=aes256-cbc,aes256-ctr" >> /home/ansible/.ssh/config

# Initialisation du répertoire "/etc/ansible", création de l'arborescence, génération d'un fichier de configuration "ansible.cfg", et création de l'inventaire
mkdir -p /etc/ansible/{playbooks,roles,group_vars,host_vars,clients,cisco}
cd "/etc/ansible"
ansible-config init --disabled > ansible.cfg
touch "/hosts"

# Désactivation de la vérification de signature dans le fichier de configuration "ansible.cfg"
sed -i 's/host_key_checking=True/host_key_checking=False/' ansible.cfg

# Configuration du répertoire des playbooks dans le fichier de configuration "ansible.cfg"
sed -i 's/:\/etc\/ansible\/roles/:\/etc\/ansible\/roles:\/etc\/ansible\/playbooks/' ansible.cfg

# Configuration du timeout pour les commandes ansible dans le fichier de configuration "ansible.cfg"
sed -i 's/command_timeout=30/command_timeout=180/' ansible.cfg

# Configuration du fichier "/etc/hosts" pour la résolution de nom des équipements réseaux
echo -e "192.168.51.254 SW1-CORE\n192.168.254.254 RT1-CORE" | tee -a /etc/hosts

# Défintion des groups d'hôtes "ciscorouter" & "ciscoswitch" ajout de l'hôte RT1-CORE (192.168.254.254) & SW1-CORE (192.168.51.254)
echo -e "[ciscorouter]\nRT1-CORE" | tee -a /etc/ansible/hosts
echo -e "[ciscoswitch]\nSW1-CORE" | tee -a /etc/ansible/hosts

# Définitions des divers variables nécessaire au fonctionnement des modules "cisco.ios" dans le fichier de variable "/etc/ansible/group_vars/all"
echo -e "ansible_connection: ansible.netcommon.network_cli\nansible_network_os: cisco.ios.ios\nansible_user: cisco\nansible_password: cisco\nansible_become: yes\nansible_become_method: enable\nansible_become_password: cisco\n" | tee -a /etc/ansible/group_vars/all.yml
echo -e 'ftp_username: "ansible"\nftp_password: "ansible"\nftp_server_name: "SRV-FTP"\nftp_ip_address: "192.168.30.3"\nansible_command_timeout: "180"\nsnmp_user: "ansible"\nsnmp_password: "ansible"\nsnmp_priv_password: "ansible"\n' | tee -a /etc/ansible/group_vars/all.yml

# Création des répertoires différents rôles ansible
ansible-galaxy init /etc/ansible/roles/create-ssh-key
ansible-galaxy init /etc/ansible/roles/create-ssh-user
ansible-galaxy init /etc/ansible/roles/deploy-ssh-key
ansible-galaxy init /etc/ansible/roles/read-config
ansible-galaxy init /etc/ansible/roles/backup-config
ansible-galaxy init /etc/ansible/roles/read-system-info
ansible-galaxy init /etc/ansible/roles/backup-image
ansible-galaxy init /etc/ansible/roles/import-image-router
ansible-galaxy init /etc/ansible/roles/import-image-switch
ansible-galaxy init /etc/ansible/roles/configure-snmp
ansible-galaxy init /etc/ansible/roles/configure-vlan

# Création des fichiers des playbooks
touch ./playbooks/{cisco-auth.yml,cisco-info.yml,cisco-update.yml,cisco-config.yml}

# Changement d'utilisateur "root" -> "ansible"
su ansible