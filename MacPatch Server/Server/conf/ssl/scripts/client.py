#!/usr/bin/python
#
# Creates client certificates
#

import os, sys, argparse


BASEDIR = "/Library/MacPatch/Server/conf/ssl"
# Feel free to change C, ST, L
# Must Match CERTSUB from CA.py
CERTSUB = "/C=US/ST=California/L=Livermore/O=MacPatch/OU=Master"

# Process opts, argparse will parse opts and create help, usage and version information
parser = argparse.ArgumentParser(description='Used to create client certificates', version='%(prog)s 1.0')
parser.add_argument('-d', dest='ADEVCUUID', metavar='Device CUUID', required=True, help='client device ID')
parser.add_argument('-n', dest='AHOSTNAME', metavar='Hostname', required=True, help='client hostname')
parser.add_argument('-p', dest='APASSWORD', metavar='Password', required=True, help='enclose in single quotes, ex: \'p@$$w0rd\'')

# Get opts from argparse
opts = parser.parse_args()

# Validate required opts
#   Handled in argparse with "required=True"

# Make sure client ID dir exists
CLIENTDIR = os.path.join(BASEDIR, "client", opts.ADEVCUUID)
if not os.path.isdir(CLIENTDIR):
    os.makedirs(CLIENTDIR)  # makedirs() will create intermediate folders

# Create and sign a client cert
print "Creating and signing a client cert ..."
theCommand = 'openssl req -config ' + os.path.join(BASEDIR, 'openssl.cnf') + ' -new -subj ' + CERTSUB + '/CN=' + opts.AHOSTNAME + ' -nodes -keyout ' + os.path.join(CLIENTDIR, opts.ADEVCUUID + '.key') + ' -out ' + os.path.join(CLIENTDIR, opts.ADEVCUUID + '.csr')
returnCode = os.system(theCommand)

if returnCode != 0:
    print "Error: 100"
    sys.exit(100)

# Have the RootCA sign the CSR and create a signed certificate
print "RootCA will sign the CSR and create a signed certificate ..."
theCommand = 'openssl ca -batch -config ' + os.path.join(BASEDIR, 'openssl.cnf') + ' -extensions client_cert -in ' + os.path.join(CLIENTDIR, opts.ADEVCUUID + '.csr') + ' -out ' + os.path.join(CLIENTDIR, opts.ADEVCUUID + '.pem')
returnCode = os.system(theCommand)

if returnCode != 0:
    print "Error: 200"
    sys.exit(200)

# Export the signed client certificate and the private RSA key into a PKCS#12 file
print "Exporting the singed client certificate and the private RSA key into a PKCS#12 file ..."
theCommand = 'openssl pkcs12 -export -in ' + os.path.join(CLIENTDIR, opts.ADEVCUUID + '.pem') + ' -inkey ' + os.path.join(CLIENTDIR, opts.ADEVCUUID + '.key') + ' -name "' + opts.ADEVCUUID + ' Client Certificate" -certfile ' + os.path.join(BASEDIR, 'ca', 'ca.crt') + ' -out ' + os.path.join(CLIENTDIR, arg.ADEVCUUID + '.p12') + ' -password pass:' + opts.APASSWORD
returnCode = os.system(theCommand)

if returnCode != 0:
    print "Error: 300"
    sys.exit(300)

print "Certificate successfully generated for " + opts.AHOSTNAME