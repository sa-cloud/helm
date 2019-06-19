#!/bin/bash

#set -o nounset \
#    -o errexit \
#    -o verbose \
#    -o xtrace

# This script generates all the server and client sertificates needed to install secured kafka **with only one broker** and to connect to it from a client application.
# To have more brokers - a server sertificate needs to be created for each one.

# **Note: to run this script - update  kafkadomain variable to the correct value <broker pod name>.<headless service name>.<namespace>.svc.cluster.local

# This script converts kafka.client.keystore.jks into ca_cert.pem + client_key.pem which are used by rdkafka.

# To install kafka: use bitnami helm chart with the generated kafka.server.keystore.jks and kafka.server.trustore.jks, and some user+pass
# (kafka.server.trustore.jks must be renamed to kafka.trustore.jks and kafka.server.keystore.jks to kafka.keystore.jks to be mapped correctly in the secret and consumed by kafka server):
# https://github.com/bitnami/charts/tree/master/bitnami/kafka#enable-security-for-kafka-and-zookeeper
# helm repo add bitnami https://charts.bitnami.com/bitnami
# sudo helm install --name dh-kafka --namespace cert-manager --set persistence.enabled=false --set zookeeper.persistence.enabled=false --set auth.enabled=true --set auth.brokerUser=usr --set auth.brokerPassword=pwd123 --set auth.certificatesSecret=kafka-certificates --set auth.certificatesPassword=test1234 bitnami/kafka --tls

# To use kafka from client app: add files ca-cert, client_cert.pem, client_key.pem to the docker image of the client app and use the following configurations:
# SECURITY_PROTOCOL: 'sasl_ssl'
# SASL_MECHANISM: 'PLAIN'
# config['metadata.broker.list'] = process.env.kafkaMetadataBrokerList;
# config['sasl.username'] = process.env.kafkaSaslUsername;
# config['sasl.password'] = process.env.kafkaSaslPassword;
# config['ssl.ca.location'] = process.env.kafkaSslCaLocation; //"./certs/ca-cert"

# config['ssl.certificate.location'] = "./certs/client_cert.pem"
# config['ssl.key.location'] = './certs/client_key.pem';
# config['ssl.key.password'] = "test1234";

# Note: the bitnami image inforces client authentication by the kafka server. If it was possible to set KAFKA_SSL_CLIENT_AUTH / ssl.client.auth to "none"
# then the pem files would not be required (?)


# Cleanup files
rm -f *.crt *.csr *_creds *.jks *.srl *.key *.pem *.der *.p12

# update to the correct domain
kafkadomain=dh-kafka-0.dh-kafka-headless.cert-manager.svc.cluster.local

## 1. Create certificate authority (CA)
openssl req -new -x509 -keyout ca-key -out ca-cert -days 365 -passin pass:test1234 -passout pass:test1234 -subj "/CN=$kafkadomain/OU=sa/O=ibm/L=PaloAlto/S=Ca/C=US"

## 2. Create client keystore
keytool -noprompt -keystore kafka.client.keystore.jks -genkey -alias localhost -dname "CN=$kafkadomain, OU=sa, O=ibm, L=PaloAlto, ST=Ca, C=US" -storepass test1234 -keypass test1234

## 3. Sign client certificate
keytool -noprompt -keystore kafka.client.keystore.jks -alias localhost -certreq -file cert-unsigned -storepass test1234
openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-unsigned -out cert-signed -days 365 -CAcreateserial -passin pass:test1234

## 4. Import CA and signed client certificate into client keystore
keytool -noprompt -keystore kafka.client.keystore.jks -alias CARoot -import -file ca-cert -storepass test1234
keytool -noprompt -keystore kafka.client.keystore.jks -alias localhost -import -file cert-signed -storepass test1234

## 5. Import CA into client truststore (only for debugging with producer / consumer utilities)
keytool -noprompt -keystore kafka.client.truststore.jks -alias CARoot -import -file ca-cert -storepass test1234

## 6. Import CA into server truststore
keytool -noprompt -keystore kafka.server.truststore.jks -alias CARoot -import -file ca-cert -storepass test1234

## 7. Create PEM files for app clients
mkdir -p ssl

## 8. Create server keystore
keytool -noprompt -keystore kafka.server.keystore.jks -genkey -alias $kafkadomain -dname "CN=$kafkadomain, OU=sa, O=ibm, L=PaloAlto, ST=Ca, C=US" -storepass test1234 -keypass test1234

## 9. Sign server certificate
keytool -noprompt -keystore kafka.server.keystore.jks -alias $kafkadomain -certreq -file cert-unsigned -storepass test1234
openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-unsigned -out cert-signed -days 365 -CAcreateserial -passin pass:test1234

## 10. Import CA and signed server certificate into server keystore
keytool -noprompt -keystore kafka.server.keystore.jks -alias CARoot -import -file ca-cert -storepass test1234
keytool -noprompt -keystore kafka.server.keystore.jks -alias $kafkadomain -import -file cert-signed -storepass test1234

### Extract signed client certificate
keytool -noprompt -keystore kafka.client.keystore.jks -exportcert -alias localhost -rfc -storepass test1234 -file ssl/client_cert.pem

### Extract client key
keytool -noprompt -srckeystore kafka.client.keystore.jks -importkeystore -srcalias localhost -destkeystore cert_and_key.p12 -deststoretype PKCS12 -srcstorepass test1234 -storepass test1234
openssl pkcs12 -in cert_and_key.p12 -nocerts -nodes -passin pass:test1234 -out ssl/client_key.pem

### Extract CA certificate
keytool -noprompt -keystore kafka.client.keystore.jks -exportcert -alias CARoot -rfc -file ssl/ca_cert.pem -storepass test1234
