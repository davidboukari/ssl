# SSL 

* [List SSL files format](format_file.md)
* see: https://github.com/davidboukari/apache/blob/master/generate_certificate.md
* see https://jamielinux.com/docs/openssl-certificate-authority/certificate-revocation-lists.html
* see https://sysadmin.cyklodev.com/creer-un-certificat-ssl-auto-signe-pour-nginx/

### Installation 
```bash
yum install openssl
```
* Doc: https://gist.github.com/mohanpedala/468cf9cef473a8d7610320cff730cdd1

### version
``` 
openssl version -a
```

# ======================================
```
#!/bin/bash -x

CN=mycert.fr
SUBJ="/C=FR/ST=Ile de France/L=Paris/O=Root"
ADDEXT="DNS:www.mycert.fr,DNS:web.mycert.fr"
OU=myOU
CA=myca/mycert.fr
KEYPASS="xxxxxx"
SIZE=4096
DURATION_IN_DAYS=365

mkdir -p ${CN}

# CSR + KEY
#openssl req -new -keyout "$${CN}/{CN}.key" -newkey rsa:${SIZE} -out "${CN}/${CN}.csr" -subj "${SUBJ}/OU=${OU}/CN=${CN}" -passout pass:"${KEYPASS}" -extensions san -config <(cat /etc/ssl/openssl.cnf < (printf "[req]distinguished_name=req\n[san]\nsubjectAltName=${ADDEXT}"))

# Check CSR
#openssl req -text -noout -verify -in ${CN}/${CN}.csr

# CRT
#openssl req -x509 -nodes -days ${DURATION_IN_DAYS} -newkey rsa:${SIZE} -keyout -out ${CN}/${CN}.crt -subj "${SUBJ}/OU=${OU}/CN=${CN}" -passout pass:"${KEYPASS}" -extensions san -config <(cat /etc/ssl/openssl.cnf <(printf "[req]distinguished_name=req\n[san]\nsubjectAltName=${ADDEXT}"))
openssl req -x509 -nodes -days ${DURATION_IN_DAYS} -newkey rsa:${SIZE} -keyout  ${CN}/${CN}.key -out ${CN}/${CN}.crt -subj "${SUBJ}/OU=${OU}/CN=${CN}" -passout pass:"${KEYPASS}" -extensions san -config <(printf "[req]\ndistinguished_name=req\n[san]\nsubjectAltName=${ADDEXT}")

# Check CRT
openssl x509 -noout -text -in ${CN}/${CN}.crt

# Check CRT match with key
echo "KEY md5"
openssl rsa -noout -modulus -in ${CN}/${CN}.key  | openssl md5

echo "CRT md5"
openssl x509 -noout -modulus -in ${CN}/${CN}.crt | openssl md5

# Generate the CSR from CRT + KEY`
openssl x509 -in ${CN}/${CN}.crt -signkey ${CN}/${CN}.key -x509toreq -out ${CN}/${CN}.csr

# Check CSR
openssl req -text -noout -verify -in ${CN}/${CN}.csr

# PEM
cat ${CN}/${CN}.crt ${CN}/${CN}.key > ${CN}/${CN}.pem

# P12
openssl pkcs12 -export -out ${CN}/${CN}.p12 -inkey ${CN}/${CN}.key -in ${CN}/${CN}.pem -passout pass:"${KEYPASS}"

# jks 
if which keytool ;then
  keytool -keypass "${KEYPASS}" -storepass "${KEYPASS}" -importkeystore -srckeystore ${CN}/${CN}.p12 -srcstoretype pkcs12 -destkeystore ${CN}/${CN}.jks
else
  echo "Please install openjdk to get keytool"
fi
```


# ======================================
Generate a multi domaine certiticate multisan
```
tee multisan.conf<<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
#default_keyfile = multisan.key
prompt = no

[req_distinguished_name]
C = FR
ST = France
L = Paris
O = OrganizatioName
OU = OrganizationUnit
CN = server.domain1.com

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = server.domain1.com
DNS.2 = server.domain2.com
DNS.3 = server.domain3.com
EOF

# Generate private key & CSR
openssl req -new -nodes -newkey rsa:2048 -keyout multisan.key -out multisan.csr -config multisan.conf

# Check CSR
openssl req -text -noout -verify -in ${CN}.csr

# Build from an existing key & csr
openssl x509 -req -signkey multisan.key -in multisan.csr  -days 365 -out multisan.crt


# Or Build from existing key only
openssl -x509 req -key multisan.key -new -days 365 -out multisan.crt


```
# ======================================


# ======================================
## Generate Certificate
* https://srvfail.com/ucc-multidomain-csr/
```
# Set variables
CN=mycert.mydomain
CA=mycert.mydomain-ca
OU="myOU"
keypass="changeit"

# CSR
openssl req -new -keyout "${CN}.key" -newkey rsa:2048 -out "${CN}.csr" -subj "/C=FR/ST=Ile de France/L=Paris/O=Root/OU=${OU}/CN=${CN}"
openssl req -text -noout -verify -in ${CN}.csr

# CRT
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${CN}.key -out ${CN}.crt
```

## Build pem & pkcs12
```
openssl x509  -inform DER -in ${CN}.crt -outform PEM -out ${CN}.pem 

#if error unable to load certificate
#139624210466704:error:0D0680A8:asn1 encoding routines:ASN1_CHECK_TLEN:wrong tag:tasn_dec.c:1239:
#139624210466704:error:0D07803A:asn1 encoding routines:ASN1_ITEM_EX_D2I:nested asn1 error:tasn_dec.c:405:Type=X509
# just cp ${CN}.crt ${CN}.pem 

openssl pkcs12 -export -out ${CN}.p12 -inkey ${CN}.key -in ${CN}.pem -certfile ${CA}

#Check 
keytool -list -v -keystore ${CN}.p12
```

## Build jks
```
keytool -importkeystore -srckeystore ${CN}.p12 -srcstoretype pkcs12 -destkeystore ${CN}.jks

#Check
keytool -list -v -keystore ${CN}.jks
```

## Check all
```
openssl x509 -text -noout -in ${CN}.crt
openssl req -noout -text -in ${CN}.csr

openssl x509 -noout -modulus -in ${CN}.crt | openssl md5
openssl req  -noout -modulus -in ${cN}.csr | openssl md5
openssl rsa  -noout -modulus -in ${CN}.key | openssl md5

# get informations
openssl pkcs12 -info -in ${CN}.p12

# Get all informations in pkcs12 & jks
keytool -list -v -keystore ${CN}.p12
keytool -list -v -keystore ${CN}.jks
```


### Generate a certificate for multi domaine

* Prepare the ssl template ssl.conf

```bash
cat ssl.conf
[ req ]
default_bits       = 4096
distinguished_name = req_distinguished_name
req_extensions     = req_ext

[ req_distinguished_name ]
countryName                 = FR
stateOrProvinceName         = France
localityName                = Paris
organizationName            = Hawksysmoon
commonName                  = hawksysmoon.com
commonName_max              = 64

[ req_ext ]
subjectAltName = @alt_names

[alt_names]
DNS.1   = hawksysmoon.com
DNS.2   = www.hawksysmoon.com
DNS.3   = otherdomaine.com
```

### Generate the certificate

```bash
cat generate.sh
#!/bin/bash

openssl genrsa -out private.key 4096

openssl req -new -sha256 \
    -out private.csr \
    -key private.key \
    -config ssl.conf

openssl req -text -noout -in private.csr

openssl x509 -req \
    -sha256 \
    -days 3650 \
    -in private.csr \
    -signkey private.key \
    -out private.crt \
    -extensions req_ext \
    -extfile ssl.conf
```


### Read the CSR

```bash
openssl req -noout -text -in private.csr
```

### Read a CRT

```bash
openssl x509 -text -noout -in mycertificate.crt
```

### Read CN of a certificate
```
$ openssl x509 -noout -subject -in client.dijon.fr.crt

subject= /C=FR/ST=France/L=Paris/O=IHS/CN=client.dijon.fr
```

### Read a PEM

```bash
openssl x509 -text -noout -in certificate.pem
```

### Read CRL (Revocation Control List)

```bash
openssl crl -noout -text  -in ./crl.pem
```

### Check if a certificate is valid (check by using CA certif auth)

```bash
openssl verify -CAfile ./certs/ca.pem   ./ca/signed/node1.pem
```

### See the inventory (index.txt or inventory.txt)

```bash
cat ./ca/inventory.txt
0x0001 2019-11-07T19:01:58UTC 2024-11-06T19:01:58UTC /CN=Puppet CA: puppetmaster
0x0002 2019-11-07T19:02:34UTC 2024-11-06T19:02:34UTC /CN=puppetmaster
0x0003 2019-11-07T19:04:53UTC 2024-11-06T19:04:53UTC /CN=node1
0x0004 2019-11-12T07:36:14UTC 2024-11-11T07:36:14UTC /CN=puppetmaster.blabla
```

### Revoke a certificate

```bash
cd /root/ca
openssl ca -config intermediate/openssl.cnf -revoke intermediate/certs/bob@example.com.cert.pem
```

-----------------------------------------------------
## Create your own CA
* http://www.linux-france.org/prj/edu/archinet/systeme/ch24s03.html
```
# Check openssl version
openssl version -a

# Create the private key
openssl genrsa 1024 > servwiki.key  #add -des3 for passphrase

# Create the CSR Certificate Signing Request for the CRT
openssl req -new -key servwiki.key > servwiki.csr

# Create the CA Certification Authority key
openssl genrsa 1024 > ca.key

# Create the CA auto signed certificate CRT
openssl req -new -x509 -days 365 -key ca.key > ca.crt

# Sign the client CRT
#The option -CAcreateserial should be use only the 1st time, it will generate ca.srl.
#For the next certifications (to renew or others domaines) the ID in ca.srl will be incremented with the option -CAserial ca.srl
openssl x509 -req -in servwiki.csr -out servwiki.crt -CA ca.crt -CAkey ca.key -CAcreateserial -CAserial ca.srl

# Verify the CRT
openssl verify  -CAfile ca.crt  servwiki.crt

# Read the CRT
openssl x509 -text -noout -in ca.crt
openssl x509 -text -noout -in servwiki.crt

openssl s_client -connect www.google.com:443
openssl s_client -cert ./servwiki.crt -key  ./servwiki.key -connect www.google.com:443
openssl s_client -cert ./servwiki.crt -key  ./servwiki.key -CAfile ca.crt  -connect www.google.com:443

# Check MTLS
openssl s_client -tls1_2 -cert filebeat.crt -key filebeat.pkcs8.key -CAfile ca.crt -connect www.google.com:443
CONNECTED(00000003)
depth=2 OU = GlobalSign Root CA - R2, O = GlobalSign, CN = GlobalSign
verify return:1
depth=1 C = US, O = Google Trust Services, CN = GTS CA 1O1
verify return:1
depth=0 C = US, ST = California, L = Mountain View, O = Google LLC, CN = www.google.com
verify return:1
---
Certificate chain
 0 s:/C=US/ST=California/L=Mountain View/O=Google LLC/CN=www.google.com
   i:/C=US/O=Google Trust Services/CN=GTS CA 1O1
 1 s:/C=US/O=Google Trust Services/CN=GTS CA 1O1
   i:/OU=GlobalSign Root CA - R2/O=GlobalSign/CN=GlobalSign
---
...
...
No client certificate CA names sent
Peer signing digest: SHA256
Server Temp Key: ECDH, P-256, 256 bits
---
SSL handshake has read 3249 bytes and written 415 bytes
---
New, TLSv1/SSLv3, Cipher is ECDHE-RSA-AES128-GCM-SHA256
Server public key is 2048 bit
Secure Renegotiation IS supported
Compression: NONE
Expansion: NONE
No ALPN negotiated
...
...

# Check TLS protocols
openssl s_client -connect logstash.myelk.com:5048 -ssl3
openssl s_client -connect logstash.myelk.com:5048 -tls1
openssl s_client -connect logstash.myelk.com:5048 -tls1_1
openssl s_client -connect logstash.myelk.com:5048 -tls1_2
```
## TLS/MTLS
* https://docs.microsoft.com/fr-fr/skypeforbusiness/plan-your-deployment/security/tls-and-mtls
----------------------------------------------
### Other way

```bash
cat ../cert-sample.cfg
[ req ]
default_bits = 4096
default_keyfile = private.key
distinguished_name = req_distinguished_name
attributes = req_attributes
prompt = no

[ req_distinguished_name ]
C = CA
ST = AB
L = St. Albert
O = JBMC-Software
CN = domain.com
emailAddress = my@email.com
[ req_attributes ]
[SAN]
subjectAltName=DNS:domain.com,DNS:www.domain.com,DNS:otherdomain.com,DNS:www.otherdomain.com
```

```bash
#!/bin/bash

GENERATE_DIR=$PWD/generate
CN=hawksysmoon.com

mkdir -p $GENERATE_DIR
/usr/bin/openssl genrsa 4096 > ${GENERATE_DIR}/private.key
/usr/bin/openssl req -new -key ${GENERATE_DIR}/private.key

/usr/bin/openssl req -new -sha256 -key ${GENERATE_DIR}/private.key -subj "/CN=$CN}" -reqexts SAN -config cert.cfg
```

### openssl s_client send data
```
echo -e "GET / HTTP/1.1\r\n" | openssl s_client -cert /root/kubernetes/apachessl/donotcommit/client.dijon.fr/client.dijon.fr.crt -key  /root/kubernetes/apachessl/donotcommit/client.dijon.fr/client.dijon.fr.key  -connect localhost:9091
```

### Generate auto key and certificate
- openssl req -x509 -days 365 -nodes -newkey rsa:2048 -keyout mygrafanaperso.key -out mygrafanaperso.crt  


#-----------------------------------------------------------
#- Method 0: Auto signed Certificate
#-----------------------------------------------------------


### Generate a protected private key
openssl genrsa -des3 -out server-protected.key 2048

### Generate a CSR which contains public key
openssl req -new -key server-protected.key -out server.csr

### Read the CSR
openssl req -noout -text -in server.csr

### Unprotect the private key
openssl rsa -in server-protected.key -out server.key

### Generate the CRT 
openssl x509 -req -days 1000 -in server.csr -signkey server.key -out server.crt

### Read a CRT
openssl x509 -text -noout -in server.crt

### It is possible to concat severals CRT to on by using cat
cat domaina.crt domainb.ca.crt > certificate.alldomain.crt


#-----------------------------------------------------------
#- Command documentation
#-----------------------------------------------------------



#-----------------------------------------------------------
#- Method 1: Auto signed Certificate
#-----------------------------------------------------------


Créer un certificat SSL auto-signé pour Nginx
11/02/2014 Zephilou 2 Commentaires

Si vous ne souhaitez pas acheter un certificat SSL, il est tout a fait possible d’un générer un vous même.

On commence par créer un répertoire :

mkdir  /etc/nginx/ssl/
cd /etc/nginx/ssl/

Puis on génère une autorité de certification (CA) en spécifiant une passphrase:

openssl genrsa -des3 -out server.key 1024

Puis on spécifie les informations de l’autorité de certification :

openssl req -new -key server.key -out server.csr

Et on crée une clé allant avec le certificat :

cp server.key server.key.org
openssl rsa -in server.key.org -out server.key
openssl x509 -req -days 1000 -in server.csr -signkey server.key -out server.crt

Finalement on intègre le certificat et la clé dans la config du vhost :

server {
    listen 443 ssl;
    ssl on;
    ssl_certificate      /etc/nginx/ssl/server.crt;
    ssl_certificate_key  /etc/nginx/ssl/server.key;

On peut éventuellement ajouter le support SPDY si Nginx a été compilé avec :

server {
    listen 443 ssl spdy;
    ssl on;
    ssl_certificate      /etc/nginx/ssl/server.crt;
    ssl_certificate_key  /etc/nginx/ssl/server.key;

;-----------------------------------------------------------
;- Method 2: Generate and  Buy a validation
;-----------------------------------------------------------

```
# Generate a new key
openssl genrsa -out server.key 2048

# Generate a new CSR
openssl req -sha256 -new -key server.key -out server.csr

# Check certificate against CA
openssl verify -verbose -CApath ./CA/ -CAfile ./CA/cacert.pem cert.pem

# Self Signed
openssl req -new -sha256 -newkey rsa:2048 -days 1095 -nodes -x509 -keyout server.key -out server.pem

# crlf fix
perl -pi -e 's/\015$//' badcertwithlf.pem

# match keys, certs and requests
# Simply compare the md5 hash of the private key modulus, the certificate modulus, or the CSR modulus and it tells you whether they match or not.
openssl x509 -noout -modulus -in yoursignedcert.pem | openssl md5
openssl rsa -noout -modulus -in yourkey.key | openssl md5
openssl req -noout -modulus -in yourcsrfile.csr | openssl md5


# criar uma CA
/usr/share/ssl/misc/CA -newca

# Generate a CSR
/usr/share/ssl/misc/CA.sh -newreq

# Cert -> CSR
openssl x509 -x509toreq -in server.crt -out server.csr -signkey server.key

# Sign
/usr/share/ssl/misc/CA.sh -sign

# Decrypt private key (so Apache/nginx won't ask for it)
openssl rsa -in newkey.pem -out wwwkeyunsecure.pem
cat wwwkeyunsecure.pem >> /etc/ssl/certs/imapd.pem

# Encrypt private key AES or 3DES
openssl rsa -in unencrypted.key -aes256 -out encrypted.key
openssl rsa -in unencrypted.key -des3 -out encrypted.key

# Get some info
openssl x509 -noout -text -nameopt multiline,utf8 -in certificado.pem
openssl x509 -noout -text -fingerprint -in cert.pem
openssl s_client -showcerts -connect www.google.com:443
openssl req -text -noout -in req.pem

# list P7B
 openssl pkcs7 -in certs.p7b -print_certs -out certs.pem

# PEM -> PFX
openssl pkcs12 -export -out alvaro.p12 -name "Certificado do Alvaro" -inkey newreq.pem -in newcert.pem -certfile cacert.pem

# PFX -> pem (with key)
openssl pkcs12 -in ClientAuthCert.pfx -out ClientAuthCertKey.pem -nodes -clcerts

# DER (.crt .cer .der) to PEM
openssl x509 -inform der -in MYCERT.cer -out MYCERT.pem

# PEM -> DER
openssl x509 -outform der -in MYCERT.pem -out MYCERT.der
openssl rsa -in key.pem -outform DER -out keyout.der

# JKS -> P12
keytool -importkeystore -srckeystore keystore.jks -srcstoretype JKS -deststoretype PKCS12 -destkeystore keystore.p12

# P12 -> JKS
keytool -importkeystore -srckeystore keystore.p12 -srcstoretype PKCS12 -deststoretype JKS -destkeystore keystore.jks

# Revoke
openssl ca -revoke CA/newcerts/cert.pem
openssl ca -gencrl -out CA/crl/ca.crl
openssl crl -text -noout -in CA/crl/ca.crl
openssl crl -text -noout -in CA/crl/ca.der -inform der

# Base64 encoding/decoding
openssl enc -base64 -in myfile -out myfile.b64
openssl enc -d -base64 -in myfile.b64 -out myfile.decoded

echo username:passwd | openssl base64
echo dXNlcm5hbWU6cGFzc3dkCg== | openssl base64 -d

#  Generate a Java keystore and key pair
keytool -genkey -alias mydomain -keyalg RSA -keysize 2048 -keystore mykeystore.jks

# Generate a certificate signing request (CSR) for an existing Java keystore
keytool -certreq -alias mydomain -keyalg RSA -file mydomain.csr -keystore mykeystore.jks

# Import a root or intermediate CA certificate to an existing Java keystore
keytool -import -trustcacerts -alias ca-root -file ca-root.pem -keystore cacerts
keytool -import -trustcacerts -alias thawte-root -file thawte.crt -keystore keystore.jks

# Generate a keystore and self-signed certificate
keytool -genkey -keyalg RSA -alias selfsigned -keystore keystore.jks -storepass password -validity 360

openssl pkcs8 -topk8 -nocrypt -in key.pem -inform PEM -out key.der -outform DER
openssl x509 -in cert.pem -inform PEM -out cert.der -outform DER

# For L7: intermediate CA1 >>> intermediate CA2 >>> root CA)
openssl pkcs12 -export -in input.crt -inkey input.key -certfile root.crt -out bundle.p12

# Better DH for nginx/Apache
openssl dhparam -out dhparam.pem 2048

# Grab a certificate from a server that requires SSL authentication
openssl s_client -connect sslclientauth.reguly.com:443 -cert alvarows_ssl.pem -key alvarows_ssl.key

# openssl.cnf: subjectAltName="DNS:localhost,IP:127.0.0.1,DNS:roselcdv0001npg,DNS:roselcdv0001npg.local
```

