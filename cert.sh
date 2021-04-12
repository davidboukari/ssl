#!/bin/bash -x

CA_SRV=ca_srv
CA_CLIENT=ca_client
CERTNAME_SRV=logstash.myelk.com
CERTNAME_CLIENT=filebeat.myelk.com
DESTDIR_SRV=cert_srv
DESTDIR_CLIENT=cert_client
SERIAL=ca.srl

rm -fr $DESTDIR_SRV $DESTDIR_CLIENT
mkdir -p $DESTDIR_SRV $DESTDIR_CLIENT

# Create the private key, add -des3 for passphrase
openssl genrsa  -out ${DESTDIR_SRV}/${CERTNAME_SRV}.key  1024

# Create the CSR Certificate Signing Request for the CRT
openssl req   -new -key ${DESTDIR_SRV}/${CERTNAME_SRV}.key -out ${DESTDIR_SRV}/${CERTNAME_SRV}.csr  -config ${CERTNAME_SRV}.conf -subj "/C=FR/ST=France/L=Paris/O=MyElk/CN=logstash.myelk.com"

# Create the CA Certification Authority key
openssl genrsa -out ${DESTDIR_SRV}/ca.key 1024
#openssl x509 -in ${DESTDIR_SRV}/ca.crt -text -noout -serial|grep serial|cut -d'=' -f2 > ${DESTDIR_SRV}/${SERIAL}

# Create the CA auto signed certificate CRT
openssl req -new -x509 -days 365 -key ${DESTDIR_SRV}/ca.key  -out ${DESTDIR_SRV}/ca.crt  -config ${CA_SRV}.conf -subj "/C=FR/ST=France/L=Paris/O=MyElk/CN=myelk.com"

# Sign the client CRT
openssl x509 -req -in ${DESTDIR_SRV}/${CERTNAME_SRV}.csr -out ${DESTDIR_SRV}/${CERTNAME_SRV}.crt -CA ${DESTDIR_SRV}/ca.crt -CAkey ${DESTDIR_SRV}/ca.key  -CAcreateserial   -CAserial ${DESTDIR_SRV}/${SERIAL} -extensions v3_req -extfile ${CERTNAME_SRV}.conf



# Create the private key, add -des3 for passphrase
openssl genrsa 1024 > ${DESTDIR_CLIENT}/${CERTNAME_CLIENT}.key 

# Create the CSR Certificate Signing Request for the CRT
openssl req -new -key ${DESTDIR_CLIENT}/${CERTNAME_CLIENT}.key -out ${DESTDIR_CLIENT}/${CERTNAME_CLIENT}.csr  -subj "/C=FR/ST=France/L=Paris/O=MyElk/CN=filebeat.myelk.com"

# Create the CA Certification Authority key
#openssl genrsa -out ${DESTDIR_CLIENT}/ca.key 1024

# Create the CA auto signed certificate CRT
#openssl req -new -x509 -days 365 -key ${DESTDIR_CLIENT}/ca.key  -out ${DESTDIR_CLIENT}/ca.crt  -config ${CA_CLIENT}.conf -subj "/C=FR/ST=France/L=Paris/O=MyElk/CN=myelk.com"

cp ${DESTDIR_SRV}/ca.* ${DESTDIR_CLIENT}

# Create the CRT
#openssl x509 -req -in ${DESTDIR_CLIENT}/${CERTNAME_CLIENT}.csr -out ${DESTDIR_CLIENT}/${CERTNAME_CLIENT}.crt -CA ${DESTDIR_CLIENT}/ca.crt -CAkey ${DESTDIR_CLIENT}/ca.key -CAcreateserial  -CAserial ${DESTDIR_CLIENT}/${SERIAL} -extensions v3_req -extensions usr_cert -extfile ${CERTNAME_CLIENT}.conf
openssl x509 -req -in ${DESTDIR_CLIENT}/${CERTNAME_CLIENT}.csr -out ${DESTDIR_CLIENT}/${CERTNAME_CLIENT}.crt -CA ${DESTDIR_CLIENT}/ca.crt -CAkey ${DESTDIR_CLIENT}/ca.key  -CAserial ${DESTDIR_CLIENT}/${SERIAL} -extensions v3_req -extensions usr_cert -extfile ${CERTNAME_CLIENT}.conf

# Convert key to pkcs8
openssl pkcs8 -in ${DESTDIR_SRV}/${CERTNAME_SRV}.key -topk8 -nocrypt -out ${DESTDIR_SRV}/${CERTNAME_SRV}.pkcs8.key
openssl pkcs8 -in ${DESTDIR_CLIENT}/${CERTNAME_CLIENT}.key -topk8 -nocrypt -out ${DESTDIR_CLIENT}/${CERTNAME_CLIENT}.pkcs8.key

# Verify the CRT
openssl verify  -CAfile ${DESTDIR_SRV}/ca.crt  ${DESTDIR_SRV}/${CERTNAME_SRV}.crt
read
openssl verify  -CAfile ${DESTDIR_CLIENT}/ca.crt  ${DESTDIR_CLIENT}/${CERTNAME_CLIENT}.crt
read

# Read the CRT
openssl x509 -text -serial  -noout -in ${DESTDIR_SRV}/ca.crt
read
openssl x509 -text -serial -noout -in ${DESTDIR_SRV}/${CERTNAME_SRV}.crt
read 
openssl x509 -text -serial  -noout -in ${DESTDIR_CLIENT}/ca.crt
read
openssl x509 -text -serial -noout -in ${DESTDIR_CLIENT}/${CERTNAME_CLIENT}.crt




