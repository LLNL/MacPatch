#!/bin/bash
#
# Revoke a certificate and update the CRL.
#

BASEDIR="/Library/MacPatch/Server/conf/ssl"
ADEVCUUID=""

# ------------------------------------------
# usage 
# ------------------------------------------
usage()
{
	echo "Usage: `basename $0` options (-d \"DeviceID\") -? for help";
}

# ------------------------------------------
# validate opts
# ------------------------------------------
if ( ! getopts ":d:" opt); then
	usage
	exit $E_OPTERROR;
fi

# ------------------------------------------
# process opts
# ------------------------------------------
while getopts ":d:" opt; do
  case $opt in
    d)
      ADEVCUUID="$OPTARG"
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
if [[ -z $ADEVCUUID ]]; then
     usage
     exit $E_OPTERROR;
fi

# Revoke a particular user's certificate.
openssl ca -config $BASEDIR/openssl.cnf -revoke $BASEDIR/client/$ADEVCUUID/$ADEVCUUID.pem

# Update the CRL with the new info from the database (ie. index.txt)
openssl ca -config $BASEDIR/openssl.cnf -gencrl -out $BASEDIR/ca/ca.crl -crldays 7