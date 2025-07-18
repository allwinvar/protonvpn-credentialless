

sudo ufw logging full

sudo ufw default deny incoming
sudo ufw default deny outgoing


echo "nameserver 9.9.9.9" | sudo tee /etc/resolv.conf
sudo ufw allow out to 9.9.9.9







sudo ufw enable

sudo ufw status
sudo ufw status verbose



