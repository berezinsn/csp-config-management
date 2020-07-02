#!/bin/bash

set -xe 

# Copy operator yaml file from the google cloud bucket
gsutil cp gs://config-management-release/released/latest/config-sync-operator.yaml config-sync-operator.yaml

# Install operator
kubectl apply -f config-sync-operator.yaml

if [ `ls | grep keys | wc -l` -eq 0 ]
then 
    mkdir keys
    echo "keys dir has been created"
else 
    echo "keys dir has been detected"
fi

# Generate the key or plase your personal keys in ./keys directory
if [ `ls keys | wc -l` -eq 0 ] 
then
    ssh-keygen -q -t rsa -N '' -f ./keys/git-creds 2>/dev/null <<< y >/dev/null
    echo "Don't forget attach your public ssh key to the git accout/repo" 
else
    echo "Keys alredy exist, creating the secret"
fi

# Create K8S secret from file 
kubectl create secret generic git-creds --namespace=config-management-system --from-file=ssh=./keys/git-creds

# Nomos installation
gsutil cp gs://config-management-release/released/latest/darwin_amd64/nomos /usr/local/bin/nomos && chmod +x /usr/local/bin/nomos

# Config-management repo configuration installation via CRD
kubectl apply -f config-management.yaml

# Nomos validation
nomos vet
