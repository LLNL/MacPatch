#!/bin/sh

Version="1.0"
MP_BASE="/Library/MacPatch"
MP_SRVCONF="$MP_BASE/Server/conf"
JAVASECHOME="/System/Library/Frameworks/JavaVM.framework/Home/lib/security"

# Add Certs To KeyStore
echo "Get Certificate For (e.g. macpatch.com:2600):";
while read inputline
do
    answer="$inputline"
    if [ -z "${answer}" ]; then
        echo "answer?"
    else
        if [ ! -d "${MP_SRVCONF}/jsseCerts" ]; then
            mkdir -p "${MP_SRVCONF}/jsseCerts"
        fi

        echo "Getting cert for $answer..."
        xName=`echo $answer | awk -F . '{ print $1 }'`
        echo | openssl s_client -connect "$answer" 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > "${MP_SRVCONF}/jsseCerts/${xName}.cer"

        echo "Add $xName.cer to keystore..."
        keytool -delete -keystore "${MP_SRVCONF}/jsseCerts/jssecacerts" -storepass changeit
        keytool -import -file "${MP_SRVCONF}/jsseCerts/${xName}.cer" -alias $xName -keystore "${MP_SRVCONF}/jsseCerts/jssecacerts" -storepass changeit -trustcacerts -noprompt
    fi

    echo "Are We Done [Y/N]:"
    read d
    if [ "$d" == "Y" -o "$d" == "y" ]; then
        break
    fi	
done

echo
echo "Certificates have been download, and a jssecacerts file has been created."
echo 
echo "****** NOTE ******"
echo "A reboot will be requirerd for the application server to recognize the new cert(s)."
echo