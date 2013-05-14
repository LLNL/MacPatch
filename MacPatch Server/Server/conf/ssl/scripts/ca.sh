#!/bin/sh
#
# Used to create the initial CA
#

BASEDIR="/Library/MacPatch/Server/conf/ssl"

if [ ! -d "$BASEDIR/ca" ]; then
	mkdir -p "$BASEDIR/ca"
fi

if [ ! -d "$BASEDIR/ca/newcerts" ]; then
	mkdir -p "$BASEDIR/ca/newcerts"
fi

HOSTNAME=`hostname`

# Generate the key.
openssl genrsa -out $BASEDIR/ca/ca.key 2048

# Generate a certificate request.
openssl req -config $BASEDIR/openssl.cnf -new \
-subj "/C=US/ST=California/L=Livermore/O=MacPatch/OU=Master/CN=$HOSTNAME" \
-key $BASEDIR/ca/ca.key -out $BASEDIR/ca/ca.csr

# Self sign our root key.
openssl x509 -req -days 3650 \
-in $BASEDIR/ca/ca.csr \
-signkey $BASEDIR/ca/ca.key \
-out $BASEDIR/ca/ca.crt

# Create the CA's key database.
touch $BASEDIR/ca/index.txt

# Setup the first serial number for our keys... can be any 4 digit hex string... not sure if there are broader bounds but everything I've seen uses 4 digits.
echo "100001" > $BASEDIR/ca/serial

# Create a Certificate Revocation list for removing 'user certificates.'
openssl ca -config $BASEDIR/openssl.cnf -gencrl -out $BASEDIR/ca/ca.crl -crldays 7