#!/bin/bash
NS=$1
PNAME=$2
CNAME=${NS}"-"${PNAME}

echo -e "#### Install jq package ####"
yum -y install bind-utils > /dev/null 2>&1

chk=`which dig`
if [ $? == 0 ]
then
        echo -e "bind install Success"
else
        echo -e "bind install Fail"
fi

cd /home/ehostdev/jupyter/
./cf-dns.sh -d ehostcloud.xyz -t CNAME -n ${CNAME} -c ehostcloud.xyz -l 1 -x y

for ((i=0; i<5; i++)); do
        nslookup ${CNAME}.ehostcloud.xyz
        if [ $? == 0 ]
        then
                echo " DNS 등록 성공 "
                python3 ingress_create.py ${PNAME} ${NS} ${CNAME}.ehostcloud.xyz
                break
        else
                echo " DNS 등록 실패 "
        fi
        sleep 3
done

exit 0

kubectl kustomize client/config/crd | kubectl create -f - https://github.com/kubernetes-csi/external-snapshotter/tree/master/client/config/crd

$ cd /root/ceph-csi/examples/cephfs
# snapshotclass.yaml 에 fsid 추가 및 secret ns 확인하여 수정 후 배포
격리하여 배포하게 될 경우 namespace 추가 및 ns 관련 정보 변경 필요
$ kubectl create -f snapshotclass.yaml
$ kubectl get volumesnapshotclasses.snapshot.storage.k8s.io 
NAME                         DRIVER                DELETIONPOLICY   AGE
csi-cephfsplugin-snapclass   cephfs.csi.ceph.com   Delete           23h



if [ "$UID" -ne 0 ]; then exec sudo bash "$0" "$@"; exit; fi


cat << EOF > password.txt
> PASSWORD
> EOF

cat password.txt | sudo -S apt-get update

echo

v1.0-172ced61ce7e6b421bb2e1b9-e161830bdabd240fd74634c0adc95f7cd7dd928f622c9122b336f344d85de2b5d227ab7d3d63e720210b9523b7571c387b604b1649d4894e2bac59fb704aed010fd90da79a1bc8ba


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
    --from-literal key=v~~
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
chk=`kubectl get originissuer.cert-manager.k8s.cloudflare.com prod-issuer -o json | jq .status.conditions | grep True`
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
