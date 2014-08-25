#!/usr/bin/python
#
# Used to create the initial CA
#

import os
import socket


BASEDIR = '/Library/MacPatch/Server/conf/ssl'
CERTSUB = '/C=US/ST=California/L=Livermore/O=MacPatch/OU=Master'
HOSTNAME = socket.gethostname()

if not os.path.isdir(os.path.join(BASEDIR, 'ca', 'newcerts')):
	os.makedirs(os.path.join(BASEDIR, 'ca', 'newcerts'))

# Generate the key.
theCommand = 'openssl genrsa -out ' + os.path.join(BASEDIR, 'ca', 'ca.key') + ' 2048'
os.system(theCommand)

# Generate a certificate request.
theCommand = 'openssl req -config ' + os.path.join(BASEDIR, 'openssl.cnf') + ' -new -subj "' + CERTSUB + '"/CN="' + HOSTNAME + '" -key ' + os.path.join(BASEDIR, 'ca', 'ca.key') + ' -out ' + os.path.join(BASEDIR, 'ca', 'ca.csr')
os.system(theCommand)

# Self sign our root key.
theCommand = 'openssl x509 -req -days 3650 -in ' + os.path.join(BASEDIR, 'ca', 'ca.csr') + ' -signkey ' + os.path.join(BASEDIR, 'ca', 'ca.key') + ' -out ' + os.path.join(BASEDIR, 'ca', 'ca.crt')
os.system(theCommand)

# Create the CA's key database.
open(os.path.join(BASEDIR, 'ca', 'index.txt'), 'w')

# Setup the first serial number for our keys... can be any 4 digit hex string... not sure if there are broader bounds but everything I've seen uses 4 digits.
open(os.path.join(BASEDIR, 'ca', 'serial'), 'w').write('100001\n')

# Create a Certificate Revocation list for removing 'user certificates.'
theCommand = 'openssl ca -config ' + os.path.join(BASEDIR, 'openssl.cnf') + ' -gencrl -out ' + os.path.join(BASEDIR, 'ca' + 'ca.crl') + ' -crldays 7'
os.system(theCommand)
