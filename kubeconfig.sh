#!/bin/bash

echo "##### START of Setup kubeconfig! #####"
CLUSTER=kubernetes
NS=""
# Get parameter
if ([ $# == 0 ]) || ([ $# -eq 1 ] && [ "$1" == "-h" -o "$1" == "--help" ]); then
  echo "setup-config [<CLUSTER>] <NAMESPACE>"
  echo " CLUSTER: cluster명이며 기본값은 kubernetes이며 생략할 수 있음"
  echo " NAMESPACE: namespace. 필수값임"
  exit 2
fi

if [ $# == 1 ]; then
  NS=$1
elif [ $# == 2 ]; then
  CLUSTER=$1
  NS=$2
fi

# check user and create if not

# Switch to kubernetes-admin context
#kubectl config use-context kubernetes-admin@kubernetes

# Create namespace if not exists
chk=`kubectl get ns | grep ${NS}`
if [ $? == 1 ]; then
  echo "[ Create namespace ${NS} ]"
  kubectl create ns ${NS}
else
  echo "[ namespace ${NS} already exists ]"
fi
echo -e "\n"

# Create service account if not exists
chk=`kubectl get sa -n ${NS} | grep sa-${NS}`
if [ $? == 1 ]; then
  echo "[ Create serviceaccount sa-${NS} ]"
  kubectl create sa sa-${NS} -n ${NS}

else
  echo "[ serviceaccount sa-${NS} already exists in ${NS} ]"
fi
echo -e "\n"

# Create role
chk=`kubectl get role -n ${NS} | grep ro-sa-${NS}`
if [ $? == 1 ]; then
  echo "[ Create role ro-sa-${NS} ]"
  kubectl create role ro-sa-${NS} --verb=get --verb=list --verb=watch --resource=pods -n ${NS}
else
  echo "[ role ro-sa-${NS} already exists ]"
fi
echo -e "\n"

# Create rolebinding: admin role for sa to created namespace
chk=`kubectl get rolebinding -n ${NS} | grep rb-sa-${NS}`
if [ $? == 1 ]; then
  echo "[ Create rolebinding rb-sa-${NS} ]"
  kubectl create rolebinding rb-sa-${NS} --clusterrole=admin --serviceaccount=${NS}:sa-${NS} -n ${NS}
else
  echo "[ rolebinding rb-sa-${NS} already exists ]"
fi
echo -e "\n"

# Create rolebinding: view clusterrole for sa to all namespace
#chk=`kubectl get clusterrolebinding | grep crb-view-sa-${NS}`
#if [ $? == 1 ]; then
#  echo "[ Create clusterrolebinding rb-view-sa-${NS} ]"
#  kubectl create clusterrolebinding rb-view-sa-${NS} --clusterrole=view --serviceaccount=${NS}:sa-${NS}
#else
#  echo "[ clusterrolebinding rb-view-sa-${NS} already exists ]"
#fi

# Get token of the serviceaccount
secret=`kubectl get secret -n ${NS} | grep sa-${NS} | cut -d " " -f1`
TOKEN=`kubectl describe secret ${secret} -n ${NS} | grep token: | cut -d ":" -f2 | tr -d " "`

# Cluster info
echo "[ Create cluster info in kubeconfig ]"
  kubectl config set-cluster ${CLUSTER} --server=https://192.168.137.100:6443 --insecure-skip-tls-verify --kubeconfig=/root/.kube/${NS}.config
echo -e "\n"

# Create user
chk=`kubectl config view | grep "name: sa-{NS}"`
if [ $? == 1 ]; then
  echo "[ Create user sa-${NS} in kubeconfig ]"
  kubectl config set-credentials sa-${NS} --token=${TOKEN}
  kubectl config set-credentials sa-${NS} --token=${TOKEN} --kubeconfig /root/.kube/${NS}.config
else
  echo "[ User sa-${NS} already exists in kubeconfig ]"
fi
echo -e "\n"

# Create context
chk=`kubectl config view | grep "name: ${NS}"`
if [ $? == 1 ]; then
  echo "[ Create context ${NS} ]"
  kubectl config set-context ${NS} --user=sa-${NS} --cluster=${CLUSTER} --namespace=${NS}
  kubectl config set-context ${NS} --user=sa-${NS} --cluster=${CLUSTER} --namespace=${NS} --kubeconfig /root/.kube/${NS}.config
else
  echo "[ Context ${NS} already exists in kubeconfig ]"
fi
echo -e "\n"

# Current-context info
echo "[ Create current-context info in kubeconfig ]"
  kubectl config set-context ${NS} --cluster=${CLUSTER} --namespace=${NS} --user=sa-${NS} --kubeconfig=/root/.kube/${NS}.config
  kubectl config use-context ${NS} --kubeconfig=/root/.kube/${NS}.config
echo -e "\n"

# Test
current=`kubectl config current-context`
#kubectl config use-context ${NS}
kubectl get all -n ${NS}
if [ $? == 0 ]; then
  echo "SUCCESS to setup kubeconfig !!!"
else
  echo "FAIL to setup kubeconfig !!!"
fi
echo -e "\n"

echo "[ Transfer kubeconfig file ]"
echo -n "Enter your IP : "
read IP
echo -n "Enter your ID : "
read ID

scp /root/.kube/${NS}.config $ID@$IP:/C:
echo -e "\n"

echo "##### END of Setup kubeconfig! #####"

exit 0
