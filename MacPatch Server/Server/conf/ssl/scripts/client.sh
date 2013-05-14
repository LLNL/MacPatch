#!/bin/bash
#
# Used to create client certificates
#

BASEDIR="/Library/MacPatch/Server/conf/ssl"
# Feel free to change C, ST, L
CERTSUB="/C=US/ST=California/L=Livermore/O=MacPatch/OU=Clients"
ADEVCUUID=""
AHOSTNAME=""
APASSWORD=""

# ------------------------------------------
# usage 
# ------------------------------------------
usage()
{
	echo "Usage: `basename $0` options (-d \"DeviceID\") (-n \"HostName\") (-p \"Password\") -? for help";
}

# ------------------------------------------
# validate opts
# ------------------------------------------
if ( ! getopts ":d:n:p:" opt); then
	usage
	exit $E_OPTERROR;
fi

# ------------------------------------------
# process opts
# ------------------------------------------
while getopts ":d:n:p:" opt; do
  case $opt in
    d)
      ADEVCUUID="$OPTARG"
      ;;
    n)
      AHOSTNAME="$OPTARG"
      ;;
    p)
      APASSWORD="$OPTARG"
      ;;    
    \?)
      usage
      exit $E_OPTERROR;
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# ------------------------------------------
# validate required opts
# ------------------------------------------
if [[ -z $AHOSTNAME ]] || [[ -z $ADEVCUUID ]] || [[ -z $APASSWORD ]]
then
     usage
     exit $E_OPTERROR;
fi

# Make sure client dir exists
if [ ! -d "$BASEDIR/client" ]; then
	mkdir "$BASEDIR/client"
fi
              
# ------------------------------------------
# create and sign client cert
# ------------------------------------------
if [ -d $BASEDIR/client/$ADEVCUUID ]; then
	TS=$(date +%Y%m%d%H%M%S)
	mv $BASEDIR/client/$ADEVCUUID $BASEDIR/client/$ADEVCUUID.$TS	
fi

mkdir -p $BASEDIR/client/$ADEVCUUID


# Generate a certificate request.
openssl req -config $BASEDIR/openssl.cnf -new \
-subj "$CERTSUB/CN=$AHOSTNAME" \
-nodes -keyout $BASEDIR/client/$ADEVCUUID/$ADEVCUUID.key \
-out $BASEDIR/client/$ADEVCUUID/$ADEVCUUID.csr

if [ $? -gt 0 ]; then
	exit 1
fi

# Have the RootCA sign the CSR and create a signed certificate
openssl ca -batch -config $BASEDIR/openssl.cnf -extensions client_cert \
-in $BASEDIR/client/$ADEVCUUID/$ADEVCUUID.csr \
-out $BASEDIR/client/$ADEVCUUID/$ADEVCUUID.pem

if [ $? -gt 0 ]; then
	exit 1
fi

# Export the signed client certificate and the
# private RSA key into a PKCS#12 file
openssl pkcs12 -export -in $BASEDIR/client/$ADEVCUUID/$ADEVCUUID.pem \
-inkey $BASEDIR/client/$ADEVCUUID/$ADEVCUUID.key \
-name "$ADEVCUUID Client Certificate" -certfile \
$BASEDIR/ca/ca.crt -out $BASEDIR/client/$ADEVCUUID/$ADEVCUUID.p12 \
-password pass:${APASSWORD}

if [ $? -gt 0 ]; then
	exit 1
fi

echo                
echo "Certificate generated for $AHOSTNAME"
echo