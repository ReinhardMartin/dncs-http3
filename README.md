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
The network setup is very simple: one host is connected directly to a router which is further connected to 2 hosts, used as servers, via a switch.

![image](https://user-images.githubusercontent.com/91339156/139425518-d47663bb-36d5-4a3c-b117-4209f51d344c.png)

For the performance evaluation to be realistic, we included both web-page static contents and also video streaming (the most popular medium nowadays).
Our `client` will run the software necessary for the performance evaluation, on the other hand the `web-server` and `video-server` will run each 3 Docker containers.    
It is important to highlight that HTTP/3 protocol requires the use of port 80 and 443.
