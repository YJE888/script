#!/bin/bash -e
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

NS=""
if [ $# == 0 ]; then
        echo -e "${BLUE}shell_script.sh <namespace>${NC}"
        echo -e "${RED}<namespace>는 필수값임${NC}"
        exit 2
fi

NS=$1

chk=`kubectl get ns | grep ${NS}`
if [ $? == 0 ]
then
	echo "namespace ${NS} exists"
else
	echo -e "${RED}${NS} namespace does not exist${NC}"
	exit 2
fi

echo -e "${BLUE}#### Install jq package ####${NC}"
yum -y install jq > /dev/null 2>&1

chk=`which jq`
if [ $? == 0 ]
then
	echo -e " jq install ${GREEN}Success${NC}"
else
	echo -e " jq install ${RED}Fail${NC}"
fi

echo -e "${BLUE}#### Create the Secret ####${NC}"


chk=`kubectl get secret -n ${NS} | grep service-key`
if [ $? == 0 ]
then
	echo -e " Create the Secret ${GREEN}Success${NC}"
else
	echo -e " [ Create the Secret ]"
kubectl create secret generic \
    -n ${NS} service-key \
    --from-literal key=v[v로 시작하는 값 입력]
fi

echo -e "${BLUE}#### Create the OriginIssuer ####${NC}"

chk=`kubectl get -n ${NS} originissuers.cert-manager.k8s.cloudflare.com | grep prod-issuer`
if [ $? == 0 ]
then
        echo -e "OriginIssuer already exists"
else
        echo -e "[ Create the OriginIssuer ]"
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.k8s.cloudflare.com/v1
kind: OriginIssuer
metadata:
  name: prod-issuer
  namespace: ${NS}
spec:
  requestType: OriginECC
  auth:
    serviceKeyRef:
      name: service-key
      key: key
EOF
fi

echo -e "${BLUE}#### Check OriginIssuer status ####${NC}"
chk=`kubectl get originissuer.cert-manager.k8s.cloudflare.com prod-issuer -n ${NS} -o json | jq .status.conditions | grep True`
if [ $? == 0 ]
then
        echo -e " OriginIssuer status is ${GREEN}TRUE${NC} "
else
        echo -e " OriginIssuer status is ${RED}FALSE${NC} "
fi

echo -e "${BLUE}#### Create the Certificate ####${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ehostcloud-com
  namespace: ${NS}
spec:
  secretName: ehostcloud-com-tls
  dnsNames:
    - ehostcloud.xyz
    - "*.ehostcloud.xyz"
  duration: 168h
  renewBefore: 24h
  issuerRef:
    group: cert-manager.k8s.cloudflare.com
    kind: OriginIssuer
    name: prod-issuer
EOF

echo -e "${BLUE}#### Check Certificate status ####${NC}"
sleep 10
chk=`kubectl get -n ${NS} certificate | grep True`
if [ $? == 0 ]
then
        echo -e "  Certificate status is ${GREEN}TRUE${NC}"
else
        echo -e "  Certificate status is ${RED}Fail${NC}"
fi


exit 0
