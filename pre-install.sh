echo "SETUP CEPH PREINSTALL!"

echo -e "TURN OFF FIREWALLD"
systemctl stop firewalld
systemctl disable firewalld

echo -e "SETUP HOSTFILE"
#echo -n "Enter the new hostname: "
#read HOST
#echo -n "Enter the new host's IP: "
#read IP
cat <<EOF >> /etc/hosts
192.168.137.199 mon1
192.168.137.200 mon2
192.168.137.201 osd-1
192.168.137.202 osd-2
192.168.137.203 osd-3
192.168.137.204 osd-4
#192.168.137.198 mon3
#192.168.137.205 osd-5
#$IP     $HOST
EOF

echo -e "INSTALL PYTHON3"
yum -y install python3

echo -e "INSTALL NTP"
yum -y install ntp
sed -i 's|server 0.centos.pool.ntp.org iburst|server kr.pool.ntp.org|' /etc/ntp.conf
sed -i 's|server 1.centos.pool.ntp.org iburst|server time.bora.net|' /etc/ntp.conf
sed -i 's|server 2.centos.pool.ntp.org iburst|#server 2.centos.pool.ntp.org iburst|' /etc/ntp.conf 
sed -i 's|server 3.centos.pool.ntp.org iburst|#server 3.centos.pool.ntp.org iburst|' /etc/ntp.conf
systemctl start ntpd
systemctl enable ntpd
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

echo -e "INSTALL DOCKER"
yum install -y yum-utils \
device-mapper-persistent-data \
lvm2
yum-config-manager \
--add-repo \
https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce
systemctl start docker
systemctl enable docker
