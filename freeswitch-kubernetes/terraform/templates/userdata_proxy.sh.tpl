#!/bin/bash
# Bootstrapping script for K8s Proxy Host
set -e
export DEBIAN_FRONTEND=noninteractive

# Pre-configure debconf to avoid prompts during iptables-persistent install
echo iptables-persistent iptables-persistent/prules select true | debconf-set-selections
echo iptables-persistent iptables-persistent/prev6rules select true | debconf-set-selections

apt-get update -y
apt-get install -y nginx iptables-persistent curl

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# Setup NAT / DNAT rules
PRIVATE_FS_IP="${private_fs_ip}"

# SIP (UDP 5060)
iptables -t nat -A PREROUTING -p udp --dport 5060 -j DNAT --to-destination $PRIVATE_FS_IP:5060
# SIP (TCP 5060)
iptables -t nat -A PREROUTING -p tcp --dport 5060 -j DNAT --to-destination $PRIVATE_FS_IP:5060
# RTP range (UDP 16384-32768)
iptables -t nat -A PREROUTING -p udp --dport 16384:32768 -j DNAT --to-destination $PRIVATE_FS_IP
# Kubernetes API (TCP 6443)
iptables -t nat -A PREROUTING -p tcp --dport 6443 -j DNAT --to-destination $PRIVATE_FS_IP:6443

# POSTROUTING Masquerade
iptables -t nat -A POSTROUTING -j MASQUERADE

# Save iptables rules
netfilter-persistent save

# Configure Nginx Reverse Proxy
cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    location /pgadmin/ {
        proxy_pass http://\$PRIVATE_FS_IP:5050/;
        proxy_set_header Host \$\$host;
        proxy_set_header Host \$\$http_host;
        proxy_set_header X-Real-IP \$\$remote_addr;
        proxy_set_header X-Forwarded-For \$\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$\$scheme;
        proxy_set_header X-Script-Name /pgadmin;
        proxy_redirect off;
    }

    location /leads/ {
        proxy_pass http://\$PRIVATE_FS_IP:8080/;
        proxy_set_header Host \$\$host;
        proxy_set_header X-Real-IP \$\$remote_addr;
        proxy_set_header X-Forwarded-For \$\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$\$scheme;
    }
}
EOF

systemctl restart nginx
