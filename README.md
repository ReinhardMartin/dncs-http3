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
- reserve 1024 MB of RAM to the client and server in order to run Google Chrome and the Docker containers
- enable the _X11 forwarding_ necessary to use the browser and the related performance evaluation tools
```
config.ssh.forward_agent = true
config.ssh.forward_x11 = true
```

All the provisioning scripts are in the `vagrant` folder and are used mainly for routing and the installation of basic softwares.

# Docker
To run the Docker containers we first need to build a Docker image 
