#!/bin/bash
# Create a cert and key with openssl
#
# Functions
die () { 
  echo
  echo "Create Self-Signed Certificates

  NAME
    create_ssl_certs - create ssl self-signed ssl certificates

  SYNOPSIS
    create_ssl_certs [-ehru]

  OPTIONS
    -e | --expiry     number of days until the certificate expires. Default is 365.
    -f | --fqdn       fqdn or hostname for Common Name (CN)
    -h | --help       help informaition about this program

  EXAMPLE
    Create a certificate that expires in 100 days and CN test.example.com - create_ssl_certs --expiry 100 --fqdn test.example.com"
  exit 1
}
# Variables
DAYS_TO_EXPIRE=365
FQDN=wild.example.com
DIR=$(pwd)

# Extension file for SANS and other things
echo 'subjectAltName = DNS:test.example.com,DNS:test1.example.com,DNS:test2.example.com,DNS:wild.example.com' > ./ca/extfile.cnf
# idiomatic parameter and option handling in sh
while test $# -gt 0
do
  case "$1" in
	-e | --expiry) DAYS_TO_EXPIRE="$2"
	    ;;
  -f | --fqdn) FQDN="$2"
      ;;
  -a | --cert-authority) CA="$2"
      ;;
  - | --cert-authority) CA="$2"
      ;;
  -h | --help) die
      ;;
  -u) uri="$2"
      ;;
	*)
		;;
  esac
  shift
done


# Remove existing certs, if any
rm -rf $DIR/certs/$FQDN

# Make certs directory
mkdir -p $DIR/certs/$FQDN

# Reset db
rm $DIR/ca/db/index.txt && touch $DIR/ca/db/index.txt

# Create key
openssl genrsa -out $DIR/certs/$FQDN/$FQDN.key 4096

# Create csr
openssl req -new -subj "/C=US/ST=Washington/L=Seattle/O=Widgets n Things/OU=doodles/CN=$FQDN/emailAddress=user@example.com" -key $DIR/certs/$FQDN/$FQDN.key -out $DIR/ca/reqs/$FQDN.csr 

# Sign csr with cnf settings
#openssl ca -batch -extensions server_cert -days $DAYS_TO_EXPIRE -notext -in ./ca/reqs/$FQDN.csr -out ./certs/$FQDN/$FQDN.crt
openssl x509 -req -in $DIR/ca/reqs/$FQDN.csr -CA $DIR/ca/certs/exampleCA.crt -CAkey $DIR/ca/certs/exampleCA.key -out $DIR/certs/$FQDN/$FQDN.crt -days $DAYS_TO_EXPIRE -extfile $DIR/ca/extfile.cnf

# Add cacert to cert
cat $DIR/certs/$FQDN/$FQDN.crt | cat - $DIR/ca/certs/exampleCA.crt > $DIR/certs/$FQDN/$FQDN.withCA.crt

# Create pfx
openssl pkcs12 -export -out $DIR/certs/$FQDN/$FQDN.withCA.pfx -inkey $DIR/certs/$FQDN/$FQDN.key -in $DIR/certs/$FQDN/$FQDN.withCA.crt -passout pass:

# Output certificate
openssl x509 -in $DIR/certs/$FQDN/$FQDN.crt -text -noout | grep 'Certificate:' -A 10
