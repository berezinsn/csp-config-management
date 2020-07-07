#!/bin/bash

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
    echo "Keys directory alredy exist, checkhing existance of the K8S secret"
fi

# Create K8S secret from file if not yet exist
SECRET_EXISTS=$(kubectl get secret git-creds -n config-management-system --no-headers --output=go-template={{.metadata.name}} 2>/dev/null)
if [ -z "${SECRET_EXISTS}" ]
then
    kubectl create secret generic git-creds --namespace=config-management-system --from-file=ssh=./keys/git-creds
else
    echo "Secret private key is already exists as a K8S secret"
fi

# Nomos installation
gsutil cp gs://config-management-release/released/latest/darwin_amd64/nomos /usr/local/bin/nomos && chmod +x /usr/local/bin/nomos

# Config-management repo configuration installation via CRD
kubectl apply -f config-management.yaml

# Nomos validation
nomos vet --path=./config-sync
