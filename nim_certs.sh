#!/bin/bash
#Create certs and upload to NIM

# Variables
NIM=nms.es.f5net.com
START_ITR=1
END_ITR=105
DIR=$(pwd)
NIM_ADMIN="admin"
NIM_PASS="admin"
CREDS=$(echo -n $NIM_ADMIN:$NIM_PASS | base64)
SYSTEM_UID=704253e9-233c-3277-bbc7-a343a3be34e2
INSTANCE=9ec4ec22-5463-56c6-9d26-ee27d815ff07
DELETE_CERTS="false"

# idiomatic parameter and option handling in sh
while test $# -gt 0
do
  case "$1" in
  -d | --delete) DELETE_CERTS="true"
    ;;
  *)
    ;;
  esac
  shift
done
for i in $(seq $START_ITR $END_ITR)
do 
  $DIR/create_cert-key.sh --expiry $i --fqdn test$i.example.com 2> /dev/null > /dev/null
  CERT=$(awk '$1=$1' ORS='\\n' $DIR/certs/test$i.example.com/test$i.example.com.crt)
  KEY=$(awk '$1=$1' ORS='\\n' $DIR/certs/test$i.example.com/test$i.example.com.key)
  CACERT=$(awk '$1=$1' ORS='\\n' $DIR/ca/certs/exampleCA.crt)
  if [ $DELETE_CERTS = "false" ]; then
    #curl -kL -X POST https://$NIM/api/platform/v1/certs -H "Authorization: Basic $CREDS" -H "Accept: application/json" -H "Content-Type: application/json" -d "{ \"name\": \"test$i\", \"certAssignmentDetails\": [ { \"assignedKeyPaths\": [ { \"cert\": \"/etc/nginx/ssl/example.com/test$i.crt\", \"key\": \"/etc/nginx/ssl/example.com/test$i.key\" } ], \"configKeyPaths\": [], \"systemUID\": \"$SYSTEM_UID\", \"type\": \"Instance\" } ], \"certPEMDetails\": { \"privateKey\": \"$KEY\", \"publicCert\": \"$CERT\", \"type\": \"PEM\",  \"password\": \"$KEY_PASS\",  \"caCerts\": [\"$CACERT\"] }, \"instanceRefs\": [\"/api/platform/v1/systems/$SYSTEM_UID/instances/$INSTANCE\"] }" 2> /dev/null | jq
    curl -kL -X POST https://$NIM/api/platform/v1/certs -H "Authorization: Basic $CREDS" -H "Accept: application/json" -H "Content-Type: application/json" -d "{ \"name\": \"test$i\", \"certAssignmentDetails\": [ { \"assignedKeyPaths\": [ { \"cert\": \"/etc/nginx/ssl/example.com/test$i.crt\", \"key\": \"/etc/nginx/ssl/example.com/test$i.key\" } ], \"configKeyPaths\": [], \"systemUID\": \"$SYSTEM_UID\", \"type\": \"Instance\" } ], \"certPEMDetails\": { \"privateKey\": \"$KEY\", \"publicCert\": \"$CERT\", \"type\": \"PEM\",  \"password\": \"$KEY_PASS\",  \"caCerts\": [\"$CACERT\"] } }" 2> /dev/null | jq
  else
      curl -kL -X DELETE https://$NIM/api/platform/v1/certs/test$i -H "Authorization: Basic $CREDS" -H "Accept: application/json" -H "Content-Type: application/json" -v 2>&1 | egrep "HTTP/2|DELETE" | egrep -v "\[|--|using"
  fi
  rm -rf $DIR/certs/test$i.example.com > /dev/null
  sleep 0.1
done



