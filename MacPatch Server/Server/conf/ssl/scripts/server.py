#!/usr/bin/python
#
# Used to create the master server Certificate
#
# Version 1.0.0
#

import os
import argparse
import socket
import sys
import platform

OS_TYPE = platform.system()

'''	
# ----------------------------------	
# Script Requires ROOT
# ----------------------------------
'''
if os.geteuid() != 0:
    exit("\nYou must be an admin user to run this script.\nPlease re-run the script using sudo.\n")

HOSTNAME = socket.gethostname()
BASEDIR = '/Library/MacPatch/Server/conf/ssl'
# Feel free to change C, ST, L
# Must Match CERTSUB from CA.py
CERTSUB = '/C=US/ST=California/L=Livermore/O=MacPatch/OU=Master/CN=' + HOSTNAME
# Paths
_openssl_cnf = os.path.join(BASEDIR, 'openssl.cnf')
_server_key = os.path.join(BASEDIR, 'server', 'server.key')
_server_csr = os.path.join(BASEDIR, 'server', 'server.csr')
_server_crt = os.path.join(BASEDIR, 'server', 'server.crt')
_ca_crt = os.path.join(BASEDIR, 'ca', 'ca.crt')
_ca_key = os.path.join(BASEDIR, 'ca', 'ca.key') 

# Process opts, argparse will parse opts and create help, usage and version information
parser = argparse.ArgumentParser(description='Used to create the master server Certificate', version='%(prog)s 1.0')
parser.add_argument('-n', dest='SIGN', action="store_false", default=True, help="don't sign")

# Get opts from argparse
SIGN = parser.parse_args().SIGN

# ------------------------------------------
# Create Certificate Signing Request & Sign
# ------------------------------------------
if SIGN:
	if not os.path.exists(os.path.join(BASEDIR, 'ca', 'ca.key')):
		print "Must create the CA before you can create the server cert."
		print
		print 'Please run the "ca.py" script.'
		print
		sys.exit(1)

if not os.path.isdir(os.path.join(BASEDIR, 'server')):
	os.makedirs(os.path.join(BASEDIR, 'server'))

# Create a key
theCommand = 'openssl genrsa -out ' + _server_key + ' 2048'
os.system(theCommand)

# Take our key and create a Certificate Signing Request for it.
if os.path.exists(_server_key) and os.path.exists(_openssl_cnf):
	theCommand = 'openssl req -config ' + _openssl_cnf + ' -new -subj ' + CERTSUB + ' -key ' + _server_key + ' -out ' + _server_csr
	os.system(theCommand)
	
else:
	print "Error: could not find needed files ('openssl.cnf' or 'server.key')"
	sys.exit(1)

if SIGN:
	# Sign this key with the MacPatch CA key.
	theCommand = 'openssl ca -batch -config ' + _openssl_cnf + ' -in ' + _server_csr + ' -cert ' + _ca_crt + ' -keyfile ' + _ca_key + ' -out ' + _server_crt
	os.system(theCommand)
	
else:
	print "Certificate Signing Request"
	print
	if os.path.exists(_server_csr):
		print open(_server_csr, 'r')
	else:
		print "Could not open server.csr, file not found."
	print

# Set permissions for client cert gen
if OS_TYPE == "Linux":
	theCommand = 'chown -R www-data:www-data ' + BASEDIR
else:
	theCommand = 'chown -R 79:70 ' + BASEDIR
	
os.system(theCommand)
