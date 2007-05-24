#!/bin/sh

#https://twiki.cern.ch/twiki/bin/view/LinuxSupport/HowToInstallPlague

cp /etc/plague/ca/mymy_ca_ca_cert.pem  ~USER/.plague-upload-ca-cert.pem
cp /etc/plague/ca/mymy_ca_ca_cert.pem  ~USER/.plague-server-ca-cert.pem
plague-certhelper.py normal --outdir=. --name=client --cadir=/etc/plague/ca/ --caname=my_ca
cp client_cert_and_blah.pem            ~USER/.plague-client-cert.pem

plague-user-manager.py /etc/plague/server/userdb add EMAIL@DOMAIN.com own_jobs job_admin user_admin server_admin
