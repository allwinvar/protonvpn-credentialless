

sudo ufw logging full

sudo ufw default deny incoming
sudo ufw default deny outgoing


<<<<<<< Updated upstream
=======
#echo "nameserver 9.9.9.9" | sudo tee /etc/resolv.conf
#sudo ufw allow out to 9.9.9.9
#sudo ufw allow out to 9.9.9.9 port 853 proto tcp

sudo ufw allow from 185.159.159.148 to any port 443 proto tcp
sudo ufw allow out to 185.159.159.148 port 443 proto tcp
echo "185.159.159.148  vpn-api.proton.me" | sudo tee -a /etc/hosts


>>>>>>> Stashed changes




sudo ufw enable

sudo ufw status
sudo ufw status verbose



