# SSL 

* [List SSL files format](format_file.md)
* see: https://github.com/davidboukari/apache/blob/master/generate_certificate.md
* see https://jamielinux.com/docs/openssl-certificate-authority/certificate-revocation-lists.html
* see https://sysadmin.cyklodev.com/creer-un-certificat-ssl-auto-signe-pour-nginx/

### Installation 
```bash
yum install openssl
```

### version
``` 
openssl version -a
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
openssl x509 -noout -subject -in client.dijon.fr.crt
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

