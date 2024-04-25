#!/bin/bash
# Description: This script generates a CA and a server certificate for the ingress controller

# generate private key 
openssl genrsa -out localRootCA.key 2048

# generate root certificate
openssl req -x509 -new -nodes -key localRootCA.key -sha256 -days 1024 -out localRootCA.crt -subj "/C=FR/ST=IDF/L=PARIS /O=LocalRootCA/OU=LocalRootCA/CN=localRootCA"

# generate a private key for the server
openssl genrsa -out server.key 2048

# generate a certificate signing request for the server
openssl req -new -key server.key -out server.csr -subj "/C=FR/ST=IDF/L=PARIS /O=LocalRootCA/OU=LocalRootCA/CN=localRootCA"

# sign the server certificate with the root certificate
openssl x509 -req -in server.csr -CA localRootCA.crt -CAkey localRootCA.key -CAcreateserial -out server.crt -days 365 -sha256

