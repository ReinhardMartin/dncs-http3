export DEBIAN_FRONTEND=noninteractive

sudo ip addr add 192.168.2.2/30 dev enp0s8
sudo ip link set dev enp0s8 up
sudo ip route add 192.168.1.0/30 via 192.168.2.1

sudo apt-get update
sudo apt-get -y install docker.io
sudo systemctl start docker
sudo systemctl enable docker

sudo docker pull reinhardmartin/dncs_http3
sudo docker run --name nginxHttp3 -d -p 80:80 -p 443:443/tcp -p 443:443/udp -v /vagrant/docker/conf/http3.web.conf:/etc/nginx/nginx.conf -v /vagrant/certs/:/etc/nginx/certs/ -v /vagrant/docker/html/:/etc/nginx/html/ reinhardmartin/dncs_http3
sudo docker run --name nginxHttp2 -d -p 90:80 -p 643:443/tcp -p 643:443/udp -v /vagrant/docker/conf/http2.web.conf:/etc/nginx/nginx.conf -v /vagrant/certs/:/etc/nginx/certs/ -v /vagrant/docker/html/:/etc/nginx/html/ reinhardmartin/dncs_http3
sudo docker run --name nginxtcp -d -p 100:80 -p 743:443/tcp -p 743:443/udp -v /vagrant/docker/conf/tcp.web.conf:/etc/nginx/nginx.conf -v /vagrant/certs/:/etc/nginx/certs/ -v /vagrant/docker/html/:/etc/nginx/html/ reinhardmartin/dncs_http3

