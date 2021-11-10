# Performance evaluation of HTTP/3 + QUIC
The goal of this project is to build a virtualized framework to compare the performance of HTTP/3 + QUIC with respect to HTTP/2 and TCP.                          
To do this we used Vagrant and Virtualbox in order to manage the virtual machines and Docker to run the web-server.

**Reference software:** https://blog.cloudflare.com/experiment-with-http-3-using-nginx-and-quiche/

## Introduction
The aim of HTTP/3 is to provide fast, reliable, and secure web connections across all forms of devices by resolving transport-related issues of HTTP/2. 
To do this, it uses a different transport layer network protocol called QUIC which brings the following benefits:
- **Speed:** only a single handshake is required to establish a connection client-server reducing the RTT drastically.
- **Security:** packets are always authenticated and encrypted.
- **Optimization:** to prevent _head-of-line blocking_ multiple streams of data are supported within a connection, in this way a lost packet only impacts those streams with data
carried in that packet.
- **Resiliency:** each connection has its unique ID that permits to survive changes in the client's IP address and port (e.g. switching from Wi-Fi to a mobile network).
- **Reliability:** unlike TCP, the QUIC protocol does not rely on a specific congestion control algorithm but it can automaticaly adapt at needs. It also improves loss recovery by
using unique packet numbers to avoid retransmission ambiguity and by using explicit signaling in acknowledgements (ACKs) for accurate RTT measurements. 

## Design
The network setup is very simple: 2 host connected to a router, one used as a client the other as a web-server.

![image](https://user-images.githubusercontent.com/91339156/140618029-a341ca21-3cb9-4e5f-b7f7-c63e3d7be3c8.png)

Our `client` will run the software necessary for the performance evaluation, on the other hand the `server` will run 3 Docker containers deploying the html pages.    
It is important to highlight that HTTP/3 protocol requires the use of port 80 and 443.

- **connection between client and router**

| NETWORK INTERFACE | DEVICE | IP ADDRESS |
| :---: | :---: | :---: |
| enp0s8 | client | 192.168.1.2/30 |
| enp0s8 | router | 192.168.1.1/30 |

- **connection between router and server**

| NETWORK INTERFACE | DEVICE | IP ADDRESS |
| :---: | :---: | :---: |
| enp0s9 | router | 192.168.2.1/30 |
| enp0s8 | server | 192.168.2.2/30 |

## Vagrant
As said earlier, Vagrant is used to manage the VMs and the networking side of the environment.                    
The `Vagrantfile` is configured in order to:
- set _ubuntu/bionic64_ as the hosts's OS
- reserve 1024 MB of RAM to the client and server in order to run _Google Chrome_ and the Docker containers
- enable the _X11 forwarding_ necessary to use the browser and the related performance evaluation tools
```
config.ssh.forward_agent = true
config.ssh.forward_x11 = true
```

All the provisioning scripts are in the `vagrant` folder and are used mainly for routing and the installation of basic softwares.

## Docker
To deploy the Docker containers we first need a Docker image which is built from a `Dockerfile` by running the following commands (in our `docker/` directory):
```
sudo docker build -t reinhardmartin/dncs_http3 .
sudo docker login
sudo docker push reinhardmartin/dncs_http3:latest
```
The Docker image is now created and ready to be downloaded, we will discuss in the **Deployment** part how to do this and how to deploy the containers.
The image used is based on NGINX 1.16.1 over Ubuntu 18.04 in order to use the [Quiche patch](https://blog.cloudflare.com/experiment-with-http-3-using-nginx-and-quiche/).

## SSL Certificates
Since QUIC need encryption we need to generate SSL/TLS certificates through _Let's Encrypt_. However, in order to generate valid certificates, it is required a real domain.
We have registered a [Duck DNS](https://www.duckdns.org/) domain with the _192.168.2.2_ IP address associated then we can run certbot:
```
sudo certbot -d HOSTNAME --manual --preferred-challenges dns certonly
```
This will generate two files: `fullchain.pem` and `privkey.pem`.
For security reason these certificates are not included in this repository.

## Websites
To make different tests our Docker containers will run each 3 HTML pages of different size:
- **Dimension -** `html/index3`

![dim](https://user-images.githubusercontent.com/91339156/140986874-1c71f6f1-5b4d-4487-8238-e4155e976609.PNG)


- **Multiverse -** `html/index2`
 
![mult](https://user-images.githubusercontent.com/91339156/140986895-0999898e-a35b-47b5-9652-4ba26c58ed60.PNG)


- **Covido -** `html/index`
 
![covid](https://user-images.githubusercontent.com/91339156/140986905-e8ffa2b2-d7c5-474a-a67c-7241095dea07.PNG)


## Deployment
We can now create the environment with `vagrant up`. Focusing on the `server.sh` script we notice the following commands:
```
sudo docker run --name nginx3 -d -p 80:80 -p 443:443/tcp -p 443:443/udp -v /vagrant/docker/conf/http3.web.conf:/etc/nginx/nginx.conf -v /vagrant/certs/:/etc/nginx/certs/ -v /vagrant/docker/html/:/etc/nginx/html/ reinhardmartin/dncs_http3

sudo docker run --name nginx2 -d -p 90:80 -p 643:443/tcp -p 643:443/udp -v /vagrant/docker/conf/http2.web.conf:/etc/nginx/nginx.conf -v /vagrant/certs/:/etc/nginx/certs/ -v /vagrant/docker/html/:/etc/nginx/html/ reinhardmartin/dncs_http3

sudo docker run --name nginx1 -d -p 100:80 -p 743:443/tcp -p 743:443/udp -v /vagrant/docker/conf/tcp.web.conf:/etc/nginx/nginx.conf -v /vagrant/certs/:/etc/nginx/certs/ -v /vagrant/docker/html/:/etc/nginx/html/ reinhardmartin/dncs_http3
```
Each command deploys a different container based on the Docker image created previously [reinhardmartin/dncs_http3](https://hub.docker.com/r/reinhardmartin/dncs_http3) with
different configurations:
- **--name nginx3:** use ports 80 - 443 with the protocol HTTP/3
- **--name nginx2:** use ports 90 - 643 with the protocol HTTP/2
- **--name nginx1:** use ports 100 - 743 with the protocol TCP

This is possible because of the configuration files located in `docker/conf/` passed by the `-v` option in Docker.                      
We have already enabled the _X11 forwarding_ and installed _Google Chrome_ on our `client`, in order to run it we can follow [these simple
instructions](https://jcook0017.medium.com/how-to-enable-x11-forwarding-in-windows-10-on-a-vagrant-virtual-box-running-ubuntu-d5a7b34363f) then launch it with the command:
```
google-chrome --enable-quic --quic-version=h3-29
```
This will be necessary for the next part.

## Performance Evaluation
All the measurements have to be taken from the client, which is accessible with the command `vagrant ssh`.
First, to have a brief overview of what has to be expected, we have a look at **httpstat**'s output (of index2.html web page)
- HTTP/3
![h3](https://user-images.githubusercontent.com/91339156/141154716-a85181d9-815a-4db2-8c05-c4df6da5e1bb.PNG)

(To be noticed that in this case the response is HTTP/2 not /3)

- HTTP/2
![h2](https://user-images.githubusercontent.com/91339156/141154728-a24e5d90-9bbc-4f9c-96ed-793711d40b38.PNG)


- TCP
![h1](https://user-images.githubusercontent.com/91339156/141154735-881b8cce-ae54-4888-b4d2-4c85d114a4d9.PNG)


It seems HTTP/2 is still a more reliable protocol in terms of speed. Now, for a more in depth analysis, we launch _Google Chrome_ where we can access our domain and test it with _Chrome Devtools_.
Important parameters to notice are the following:
- **covido**

TTFB 
index
HTTP/3 2.41 ms 0 conn
http/2 7.16 ms 1 conn 
tcp 5.40 ms 6 conn
index3
Http/3 4.09 ms 0 conn
http/2 7.50 ms 1 conn
tcp 5.63 ms 3 conn
