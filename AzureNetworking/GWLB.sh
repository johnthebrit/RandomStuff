#Commands for the setup within the Linux VM to act as an NVA

sudo apt update
sudo apt install net-tools
sudo apt list --upgradable
sudo apt upgrade

sudo chmod 777 /etc/sysctl.conf
echo"net.ipv4.ip_forward = 1">/etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf
#sudo iptables -t nat -A POSTROUTING -d 10.0.0.0/8 -j ACCEPT
#sudo iptables -t nat -A POSTROUTING -d 172.16.0.0/12 -j ACCEPT
#sudo iptables -t nat -A POSTROUTING -d 192.168.0.0/16 -j ACCEPT
#sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -j ACCEPT

#disable firewall
sudo ufw disable

#These should match those configure on the GW LB Backend pool
client_internal_vni=800
client_internal_port=10800
client_external_vni=801
client_external_port=10801
nva_lb_ip=10.200.0.5

#MTU of 4000
sudo ifconfig eth0 mtu 4000

# Internal tunnel
sudo ip link add vxlan${client_internal_vni} type vxlan id ${client_internal_vni} remote ${nva_lb_ip} dstport ${client_internal_port} nolearning
sudo ip link set vxlan${client_internal_vni} up
# External tunnel
sudo ip link add vxlan${client_external_vni} type vxlan id ${client_external_vni} remote ${nva_lb_ip} dstport ${client_external_port} nolearning
sudo ip link set vxlan${client_external_vni} up
# Optional: bridge both VXLAN interfaces together (works around routing between them)
sudo ip link add br-client type bridge
sudo ip link set vxlan${client_internal_vni} master br-client
sudo ip link set vxlan${client_external_vni} master br-client
sudo ip link set br-client up

# Optional: delete all VXLAN interfaces
sudo ip link delete vxlan${client_internal_vni}
sudo ip link delete vxlan${client_external_vni}
sudo ip link delete br-client


#Viewing information
ip a
sysctl net.ipv4.ip_forward
ifconfig vxlan${client_internal_vni}
ip -d link show vxlan${client_internal_vni}
ip -d link show vxlan${client_external_vni}
route -n


#To make this autoload
#Create a service file
sudo vim /etc/systemd/system/nvanetwork.service

[Unit]
Description=vni service

[Service]
Type=simple
ExecStart=/bin/bash /usr/local/bin/nvavnisetup.sh

[Install]
WantedBy=multi-user.target
:wq

#Create the file that actually sets up the VNIs
sudo vim /usr/local/bin/nvavnisetup.sh
<lines 20-40>
:wq

#Make usable as a service
sudo chmod 744 /usr/local/bin/nvavnisetup.sh

sudo chmod 664 /etc/systemd/system/nvanetwork.service
sudo systemctl daemon-reload
sudo systemctl enable nvanetwork.service

#To test
sudo systemctl --type service
sudo systemctl start nvanetwork.service
sudo systemctl daemon-reload