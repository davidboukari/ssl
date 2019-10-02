# -----------------------------------------------------------
# - Method 0: Auto signed Certificate
# -----------------------------------------------------------

# Generate a protected private key
openssl genrsa -des3 -out server-protected.key 2048

# Generate a CSR which contains public key
openssl req -new -key server-protected.key -out server.csr

# Read the CSR
openssl req -noout -text -in server.csr

# Unprotect the private key
openssl rsa -in server-protected.key -out server.key

#Generate the CRT 
openssl x509 -req -days 1000 -in server.csr -signkey server.key -out server.crt

#Read a CRT
openssl x509 -in server.crt -text -noout

#It is possible to concat severals CRT to on by using cat
cat domaina.crt domainb.ca.crt > certificate.alldomain.crt


# -----------------------------------------------------------
# - Command documentation
# -----------------------------------------------------------














# -----------------------------------------------------------
# - Method 1: Auto signed Certificate
# -----------------------------------------------------------


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

# -----------------------------------------------------------
# - Method 2: Generate and  Buy a validation
# -----------------------------------------------------------

