#!/bin/bash
# Create a cert and key with openssl

# Variables
#!/bin/sh
if [ $1 = "-e" ]; then
  DAYS_TO_EXPIRE=$2
else
  DAYS_TO_EXPIRE=365
fi

# This script expects a command line argument (name of cert, such as fqdn)
if [ ! $1 = "-h" ]; then 
  echo 'Argument required (name of cert & key to be created, such as fqdn)'
  echo 'Since no argument found using example.com'
  FQDN=example.com
else
  FQDN=$1
fi

# Remind user to update alt_names in myopenssl.cnf
read -n 1 -r -s -p "Be sure to edit myopenssl.cnf file and remove or add SANS. Press any key to continue..." key
echo
echo

# Remove existing certs, if any
rm -rf ./certs/$FQDN

# Make certs directory
mkdir -p ./certs/$FQDN

# Reset db
rm ./ca/db/index.txt && touch ./ca/db/index.txt

# Create key
openssl genrsa -out ./certs/$FQDN/$FQDN.key 2048
#openssl genrsa -des3 -out ./certs/$FQDN/$FQDN.key 2048 -aes-256-cbc

# Create csr
openssl req -new -config ./myopenssl.cnf -key ./certs/$FQDN/$FQDN.key -out ./ca/reqs/$FQDN.csr

# Sign csr with cnf settings
openssl ca -config ./myopenssl.cnf -extensions server_cert -days $DAYS_TO_EXPIRE -notext -in ./ca/reqs/$FQDN.csr -out ./certs/$FQDN/$FQDN.crt

# Add cacert to cert
cat ./certs/$FQDN/$FQDN.crt | cat - ./ca/certs/APMNetCA.crt > ./certs/$FQDN/$FQDN.withCA.crt

# Create pfx
openssl pkcs12 -export -out ./certs/$FQDN/$FQDN.withCA.pfx -inkey ./certs/$FQDN/$FQDN.key -in ./certs/$FQDN/$FQDN.withCA.crt

