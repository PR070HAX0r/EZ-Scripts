#!/bin/bash
#This script installs elk on a localhost using NGINX

#Download Packages
echo "Checking if packages exist"
if [[ -f elasticsearch-7.9.2-x86_64.rpm ]]
then
    echo "elasticsearch.rpm exists"
    echo "Skipping..."
else
    echo "Elasticsearch does not exist downloading..."
    wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.9.2-x86_64.rpm

fi
if [[ -f logstash-7.9.2.rpm ]]
then
    echo "logstash.rpm exists"
    echo "Skipping..."
else
    echo "Logstash does not exist downloading..."
    wget https://artifacts.elastic.co/downloads/logstash/logstash-7.9.2.rpm
fi
if [[ -f kibana-7.9.2-x86_64.rpm ]]
then
    echo "kibana.rpm exists"
    echo "Skipping..."
else
    echo "Kibana does not exist downloading..."
    wget https://artifacts.elastic.co/downloads/kibana/kibana-7.9.2-x86_64.rpm
fi

#Install dependencies
echo "Installing dependencies"
sleep 3
yum install java-1.8.0-openjdk nginx figlet -y  2>&1 > /dev/null
echo "Dependencies Installed"

#Install packages
echo "Installing packages"
rpm -i elasticsearch-7.9.2-x86_64.rpm 2>&1 > /dev/null
rpm -i logstash-7.9.2.rpm 2>&1 > /dev/null
rpm -i kibana-7.9.2-x86_64.rpm 2>&1 > /dev/null
echo "Packages Installed"

#Configure elasticsearch
echo "Configuring elasticsearch"
sed -i "s/#network.host: 192.168.0.1/network.host: localhost/g" /etc/elasticsearch/elasticsearch.yml
systemctl start elasticsearch  2>&1 > /dev/null
systemctl enable elasticsearch  2>&1 > /dev/null
echo "Elasticsearch configured"

#Check if elasticsearch is started
echo "Checking if elasticsearch is running and connectable"
URL="http://localhost:9200"
curl -s $URL 2>&1 > /dev/null
if [ $? != 0 ]; then
    echo "Elasticsearch is not running. exiting..."
    exit -1
fi
echo "Elasticsearch is connectable at $URL"

#Configure kibanas
echo "Configuring kibana"
sed -i 's/#elasticsearch.hosts/elasticsearch.hosts/g' /etc/kibana/kibana.yml
systemctl enable kibana
systemctl start kibana
echo "Kibana configured"

#Configure NGINX
echo "Configuring NGINX"
echo "server { listen 80; server_name kibana.com; location / {proxy_pass http://localhost:5601;} }" >> /etc/nginx/conf.d/kibana.conf

#Check if nginx conf works
echo "Checking if NGINX config works"
/usr//sbin/nginx -t 2>/dev/null > /dev/null
if [[ $? == 0 ]]; then
 echo "NGINX is working....starting"
else
 echo "NGINX failed"
 exit 1
fi

#Start NGINX
systemctl start nginx  2>&1 > /dev/null
systemctl enable nginx  2>&1 > /dev/null
setsebool httpd_can_network_connect 1 -P 2>&1 > /dev/null
echo "NGINX started"

#Conifgure firewall rules
echo "Configruing fireall rules"
firewall-cmd --add-port=80/tcp --permanent 2>&1 > /dev/null
firewall-cmd --add-port=443/tcp --permanent 2>&1 > /dev/null
firewall-cmd --reload 2>&1 > /dev/null
echo "Firwall rules configured"

#Check if kibana is connectable
echo "Checking if kibana is connectable"
sleep 10
kibana="http://localhost:5601"
curl -s $kibana 2>&1 > /dev/null
if [ $? != 0 ]; then
    echo "Kibana is not connectable. exiting..."
    exit -1
fi
echo "kibana is connectable at $kibana"

#Remove artifacts
echo "Removing artifacts"
rm -f elasticsearch*.rpm
rm -f logstash*.rpm
rm -f kibana*.rpm
sleep 2
echo "Artifacts removed"

figlet -t -k FINISHED ELK INSTALLATION
