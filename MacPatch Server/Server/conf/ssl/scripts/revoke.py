#!/usr/bin/python
#
# Revoke a certificate and update the CRL.
#

import os
import argparse

BASEDIR = '/Library/MacPatch/Server/conf/ssl'

# Process opts, argparse will parse opts and create help, usage and version information
parser = argparse.ArgumentParser(description='Used to revoke a certificate and update the CRL', version='%(prog)s 1.0')
parser.add_argument('-d', dest='ADEVCUUID', required=True, help='client device ID')

# Get opts from argparse
ADEVCUUID = parser.parse_args().ADEVCUUID
print ADEVCUUID

# Revoke a particular user's certificate.
theCommand = 'openssl ca -config ' + os.path.join(BASEDIR, 'openssl.cnf') + ' -revoke ' + os.path.join(BASEDIR, 'client', ADEVCUUID, ADEVCUUID + '.pem')
os.system(theCommand)

# Update the CRL with the new info from the database (ie. index.txt)
theCommand = 'openssl ca -config ' + os.path.join(BASEDIR, 'openssl.cnf') + ' -gencrl -out ' + os.path.join(BASEDIR, 'ca', 'ca.crl') + ' -crldays 7'
