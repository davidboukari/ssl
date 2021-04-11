#!/bin/bash -x

CA=ca
CERTNAME=logstash.myelk.com
CERTNAME_CLIENT=filebeat.myelk.com
DESTDIR=cert
SERIAL=ca.srl

rm -fr $DESTDIR
mkdir -p $DESTDIR

# Create the private key, add -des3 for passphrase
openssl genrsa  -out ${DESTDIR}/${CERTNAME}.key  1024

# Create the CSR Certificate Signing Request for the CRT
openssl req   -new -key ${DESTDIR}/${CERTNAME}.key -out ${DESTDIR}/${CERTNAME}.csr  -config ${CERTNAME}.conf -subj "/C=FR/ST=France/L=Paris/O=MyElk/CN=logstash.myelk.com"
#openssl req -new -key ${DESTDIR}/${CERTNAME}.key -out ${DESTDIR}/${CERTNAME}.csr  -config ${CERTNAME}.conf<<EOF
#FR
#France
#Paris
#MyElk
#myelk.com
#EOF
#exit 100
# Create the CA Certification Authority key
openssl genrsa -out ${DESTDIR}/ca.key 1024
#openssl x509 -in ${DESTDIR}/ca.crt -text -noout -serial|grep serial|cut -d'=' -f2 > ${DESTDIR}/${SERIAL}

# Create the CA auto signed certificate CRT
#openssl req -new -x509 -days 365 -key ${DESTDIR}/ca.key  -out ${DESTDIR}/ca.crt  -config ${CA}.conf -subj "/C=FR/ST=France/L=Paris/O=MyElk/CN=myelk.com"
openssl req -new -x509 -days 365 -key ${DESTDIR}/ca.key  -out ${DESTDIR}/ca.crt  -config ${CERTNAME}.conf<<EOF
FR
France
Paris
MyElk
myelk.com
EOF

# Sign the client CRT
#The option -CAcreateserial should be use only the 1st time, it will generate ca.srl.
#For the next certifications (to renew or others domaines) the ID in ca.srl will be incremented with the option -CAserial ca.srl
#if [ ! -f ${SERIAL} ];then
#  openssl x509 -req -in ${DESTDIR}/${CERTNAME}.csr -out ${DESTDIR}/${CERTNAME}.crt -CA ${DESTDIR}/ca.crt -CAkey ${DESTDIR}/ca.key -CAcreateserial -CAserial ${DESTDIR}/${SERIAL} -extensions v3_req -extfile ${CERTNAME}.conf 
#else
#  openssl x509 -req -in ${DESTDIR}/${CERTNAME}.csr -out ${DESTDIR}/${CERTNAME}.crt -CA ${DESTDIR}/ca.crt -CAkey ${DESTDIR}/ca.key  -CAserial ${DESTDIR}/${SERIAL} -extensions v3_req -extfile ${CERTNAME}.conf
#fi
openssl x509 -req -in ${DESTDIR}/${CERTNAME}.csr -out ${DESTDIR}/${CERTNAME}.crt -CA ${DESTDIR}/ca.crt -CAkey ${DESTDIR}/ca.key  -CAcreateserial   -CAserial ${DESTDIR}/${SERIAL} -extensions v3_req -extfile ${CERTNAME}.conf

exit 100

# Create the private key, add -des3 for passphrase
openssl genrsa 1024 > ${DESTDIR}/${CERTNAME_CLIENT}.key 

# Create the CSR Certificate Signing Request for the CRT
openssl req -new -key ${DESTDIR}/${CERTNAME_CLIENT}.key -out ${DESTDIR}/${CERTNAME_CLIENT}.csr  -subj "/C=FR/ST=France/L=Paris/O=MyElk/CN=filebeat.myelk.com"

openssl x509 -req -in ${DESTDIR}/${CERTNAME_CLIENT}.csr -out ${DESTDIR}/${CERTNAME_CLIENT}.crt -CA ${DESTDIR}/ca.crt -CAkey ${DESTDIR}/ca.key  -CAserial ${DESTDIR}/${SERIAL} -extensions v3_req -extensions usr_cert -extfile ${CERTNAME_CLIENT}.conf

# Convert key to pkcs8
openssl pkcs8 -in ${DESTDIR}/${CERTNAME}.key -topk8 -nocrypt -out ${DESTDIR}/${CERTNAME}.pkcs8.key
openssl pkcs8 -in ${DESTDIR}/${CERTNAME_CLIENT}.key -topk8 -nocrypt -out ${DESTDIR}/${CERTNAME_CLIENT}.pkcs8.key

# Verify the CRT
openssl verify  -CAfile ${DESTDIR}/ca.crt  ${DESTDIR}/${CERTNAME}.crt
read
openssl verify  -CAfile ${DESTDIR}/ca.crt  ${DESTDIR}/${CERTNAME_CLIENT}.crt
read

# Read the CRT
openssl x509 -text -serial  -noout -in ${DESTDIR}/ca.crt
read
openssl x509 -text -serial -noout -in ${DESTDIR}/${CERTNAME}.crt
read 
openssl x509 -text -serial -noout -in ${DESTDIR}/${CERTNAME_CLIENT}.crt




