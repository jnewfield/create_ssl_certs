#!/bin/bash
# Create a cert and key with openssl

# Variables
DAYS_TO_EXPIRE=365
FQDN=wild.example.com
# idiomatic parameter and option handling in sh
while test $# -gt 0
do
  case "$1" in
	-e) DAYS_TO_EXPIRE="$2"
	    ;;
  -h) FQDN="$2"
      ;;
  -r) rsc="$2"
      ;;
  -u) uri="$2"
      ;;
	*)
		;;
  esac
  shift
done

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

# Create csr
openssl req -new -config ./myopenssl.cnf -subj "/C=US/ST=Washington/L=Seattle/O=F5 Networks/OU=Profesional Services/CN=$FQDN/emailAddress=j.newfield@f5.com" -key ./certs/$FQDN/$FQDN.key -out ./ca/reqs/$FQDN.csr 

# Sign csr with cnf settings
openssl ca -batch -config ./myopenssl.cnf -extensions server_cert -days $DAYS_TO_EXPIRE -notext -in ./ca/reqs/$FQDN.csr -out ./certs/$FQDN/$FQDN.crt

exit 1
# Add cacert to cert
cat ./certs/$FQDN/$FQDN.crt | cat - ./ca/certs/APMNetCA.crt > ./certs/$FQDN/$FQDN.withCA.crt

# Create pfx
openssl pkcs12 -export -out ./certs/$FQDN/$FQDN.withCA.pfx -inkey ./certs/$FQDN/$FQDN.key -in ./certs/$FQDN/$FQDN.withCA.crt

