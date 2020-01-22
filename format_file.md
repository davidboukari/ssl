# SSL list files type

Sources: https://qastack.fr/server/9708/what-is-a-pem-file-and-how-does-it-differ-from-other-openssl-generated-key-file

SSL existe depuis assez longtemps pour que vous pensiez qu'il existe des formats de conteneur convenus. Et vous avez raison, il y en a. Trop de normes comme cela se produit. C’est donc ce que je sais et je suis sûr que d’autres y participeront.

    .csr - Ceci est une demande de signature de certificat. Certaines applications peuvent en générer pour les soumettre aux autorités de certification. Le format actuel est PKCS10, défini dans la RFC 2986 . Il inclut une partie / la totalité des détails de clé du certificat demandé, tels que le sujet, l'organisation, l'état, etc., ainsi que la clé publique du certificat à signer. Ceux-ci sont signés par l'autorité de certification et un certificat est renvoyé. Le certificat renvoyé est le certificat public (qui inclut la clé publique mais pas la clé privée), qui peut être lui-même sous deux formats.
    .pem - Défini dans les RFC 1421 à 1424 , il s’agit d’un format de conteneur pouvant inclure uniquement le certificat public (comme avec les installations Apache et les fichiers de certificat d’autorité de certification /etc/ssl/certs), ou peut inclure une chaîne de certificats complète comprenant une clé publique, une clé privée et certificats racine. De manière confuse, il peut également coder un CSR (par exemple, tel qu’il est utilisé ici ) car le format PKCS10 peut être traduit en PEM. Le nom vient de Privacy Enhanced Mail (PEM) , une méthode ayant échoué pour la messagerie sécurisée, mais le format de conteneur utilisé est toujours valide. Il s'agit d'une traduction en base64 des clés x509 ASN.1.
    .key - Il s’agit d’un fichier au format PEM contenant uniquement la clé privée d’un certificat spécifique. Il s’agit simplement d’un nom conventionnel et non normalisé. Dans les installations Apache, cela réside souvent dans /etc/ssl/private. Les droits sur ces fichiers sont très importants et certains programmes refuseront de charger ces certificats s’ils sont mal réglés.
    .pkcs12 .pfx .p12 - Définie à l'origine par RSA dans les standards de cryptographie à clé publique (PKCS abrégé), la variante "12" a été améliorée à l'origine par Microsoft, puis soumise ultérieurement sous le numéro RFC 7292 . Il s'agit d'un format de conteneur avec mot de passe contenant les paires de certificats publics et privés. Contrairement aux fichiers .pem, ce conteneur est entièrement chiffré. Openssl peut transformer cela en un fichier .pem avec des clés publiques et privées:openssl pkcs12 -in file-to-convert.p12 -out converted-file.pem -nodes

Quelques autres formats qui apparaissent de temps en temps:

    .der - Un moyen de coder la syntaxe ASN.1 en binaire, un fichier .pem est simplement un fichier .der codé en Base64. OpenSSL peut les convertir en .pem ( openssl x509 -inform der -in to-convert.der -out converted.pem). Windows les considère comme des fichiers de certificat. Par défaut, Windows exportera les certificats sous forme de fichiers au format .DER avec une extension différente. Comme...
    .cert .cer .crt - Fichier au format .pem (ou rarement .der) portant une extension différente, reconnu par l'explorateur Windows comme un certificat, contrairement à .pem.
    .p7b .keystore - Défini dans le RFC 2315 en tant que PKCS numéro 7, il s'agit d'un format utilisé par Windows pour l'échange de certificats. Java les comprend de manière native et les utilise souvent .keystorecomme une extension. Contrairement aux certificats de style .pem, ce format comporte une méthode définie pour inclure les certificats de chemin de certification.
    .crl - Une liste de révocation de certificats. Les autorités de certification les utilisent comme moyen de désautoriser les certificats avant leur expiration. Vous pouvez parfois les télécharger à partir des sites Web de CA.

En résumé, il existe quatre manières différentes de présenter les certificats et leurs composants:

    PEM - Régi par les RFC, il est utilisé préférentiellement par les logiciels open source. Il peut avoir une variété d'extensions (.pem, .key, .cer, .cert, etc.)
    PKCS7 - Norme ouverte utilisée par Java et prise en charge par Windows. Ne contient pas de matériel de clé privée.
    PKCS12 - Norme privée de Microsoft définie ultérieurement dans un RFC offrant une sécurité renforcée par rapport au format PEM en texte brut. Cela peut contenir du matériel de clé privée. Il est utilisé préférentiellement par les systèmes Windows et peut être librement converti au format PEM via OpenSL.
    DER - Le format parent de PEM. Il est utile de le considérer comme une version binaire du fichier PEM codé en base64. Pas couramment utilisé en dehors de Windows.
