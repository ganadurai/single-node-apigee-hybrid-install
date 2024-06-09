#!/bin/bash

set -e

source ./install-functions.sh

function validateVars() {

  if [[ -z $CLUSTER_NAME ]]; then
    echo "Environment variable CLUSTER_NAME is not set, please checkout README.md"
    exit 1
  fi

  if [[ -z $REGION ]]; then
    echo "Environment variable REGION is not set, please checkout README.md"
    exit 1
  fi

  if [[ -z $ACCOUNT_ID ]]; then
    echo "Environment variable ACCOUNT_ID is not set, please checkout README.md"
    exit 1
  fi

  if [[ -z $VPC_ID ]]; then
    echo "Environment variable VPC_ID is not set, please checkout README.md"
    exit 1
  fi

}

function installTools() {
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin
    eksctl version

    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    kubectl version --client
}

function prepEksClusterRole() {
    aws iam list-roles --query "Roles[*].RoleName" | grep "myAmazonEKSClusterRole"
    ROLES=$(aws iam list-roles --query "Roles[*].RoleName")
    match=1
    for entry in $ROLES; do
        entry=$(echo $entry | cut -d '"' -f 2)
        if [[ $entry == "myAmazonEKSClusterRole" ]]; then
            match=0
            break
        fi
    done
    if [ $match -eq 0 ]; then
        echo "Role exists deleting"

        aws iam detach-role-policy \
        --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy \
        --role-name myAmazonEKSClusterRole

        aws iam delete-role \
        --role-name myAmazonEKSClusterRole
    fi

    #Delete json file if it already exists
    if [ -f ~/eks-cluster-role-trust-policy.json ]; then
        rm ~/eks-cluster-role-trust-policy.json
    fi

    FLAGS_2="$(
        cat <<EOF >>~/eks-cluster-role-trust-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "eks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
}
EOF
    )"

    aws iam create-role \
    --role-name myAmazonEKSClusterRole \
    --assume-role-policy-document file://"~/eks-cluster-role-trust-policy.json"  > /dev/null

    aws iam attach-role-policy \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy \
    --role-name myAmazonEKSClusterRole
}

function checkClusterExists() {
    CLUSTERS=$(aws eks list-clusters --query "Clusters[*].ClusterName")
    match=1
    for entry in $CLUSTERS; do
        entry=$(echo $entry | cut -d '"' -f 2)
        if [[ $entry == "$CLUSTER_NAME" ]]; then
            match=0
            break
        fi
    done
    return $match
}

function setupCluster() {
    SUBNETS=$(aws ec2 describe-subnets --filter Name=vpc-id,Values=$VPC_ID | \
                jq -r '[.Subnets[].SubnetId] | join(",")')
    echo $SUBNETS

    #SUBNETS_SAMPLE=subnet-0dd6ea47695b61a34,subnet-06364102b8f13d1ce,subnet-0de2e60e36a911cde,subnet-0cb19133eb9aec1fb

    aws eks create-cluster --name $CLUSTER_NAME \
    --role-arn arn:aws:iam::$ACCOUNT_ID:role/myAmazonEKSClusterRole \
    --resources-vpc-config subnetIds=$SUBNETS  > /dev/null

    CLUSTER_STATUS=""
    while [[ $CLUSTER_STATUS != "ACTIVE" ]]; do
        CLUSTER_STATUS=$(aws eks describe-cluster --name $CLUSTER_NAME | jq .cluster.status | cut -d '"' -f 2)
        echo "CLUSTER STATUS:$CLUSTER_STATUS"
        sleep 5;
    done
}

function validateClusterSetup() {
    aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
    kubectl get svc
}

function prepNodegroupRole() {
    
    ROLES=$(aws iam list-roles --query "Roles[*].RoleName")
    match=1
    for entry in $ROLES; do
        entry=$(echo $entry | cut -d '"' -f 2)
        if [[ $entry == "myAmazonEKSNodeRole" ]]; then
            match=0
            break
        fi
    done

    #Delete role and detach role policy, if it already exists 
    if [ $match -eq 0 ]; then
        aws iam detach-role-policy \
        --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy \
        --role-name myAmazonEKSNodeRole
        aws iam detach-role-policy \
        --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly \
        --role-name myAmazonEKSNodeRole
        aws iam detach-role-policy \
        --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy \
        --role-name myAmazonEKSNodeRole

        aws iam delete-role --role-name myAmazonEKSNodeRole
    fi

    if [ -f ~/node-role-trust-policy.json ]; then
        rm ~/node-role-trust-policy.json
    fi
    FLAGS_2="$(
        cat <<EOF >>~/node-role-trust-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
}
EOF
    )"

    aws iam create-role \
    --role-name myAmazonEKSNodeRole \
    --assume-role-policy-document file://"~/node-role-trust-policy.json"  > /dev/null

    aws iam attach-role-policy \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy \
    --role-name myAmazonEKSNodeRole
    aws iam attach-role-policy \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly \
    --role-name myAmazonEKSNodeRole
    aws iam attach-role-policy \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy \
    --role-name myAmazonEKSNodeRole
}

function checkClusterNodegroupExists() {
    match=1
    entry=$(aws eks list-nodegroups --cluster-name $CLUSTER_NAME \
    --query "nodegroups[0]" | cut -d '"' -f 2)
    if [[ $entry == "$CLUSTER_NAME-nodegroup" ]]; then
        match=0
        break
    fi
    return $match
}

function setupClusterNodegroup() {
    SINGLE_SUBNET=$(aws ec2 describe-subnets --filter Name=vpc-id,Values=$VPC_ID | jq .Subnets[0].SubnetId | cut -d '"' -f 2)
    echo $SINGLE_SUBNET

    aws eks create-nodegroup --cluster-name $CLUSTER_NAME \
    --nodegroup-name $CLUSTER_NAME-nodegroup \
    --subnets $SINGLE_SUBNET \
    --node-role arn:aws:iam::$ACCOUNT_ID:role/myAmazonEKSNodeRole \
    --disk-size 20 \
    --instance-types 't3.xlarge' \
    --scaling-config minSize=1,maxSize=1,desiredSize=1 \
    --labels '{"cloud.google.com/gke-nodepool": "apigee-runtime"}'  > /dev/null

    NODEGROUP_STATUS=""
    while [[ $NODEGROUP_STATUS != "ACTIVE" ]]; do
        NODEGROUP_STATUS=$(aws eks describe-nodegroup --nodegroup-name $CLUSTER_NAME-nodegroup \
        --cluster-name $CLUSTER_NAME|jq .nodegroup.status | cut -d '"' -f 2)
        echo "NODEGROUP STATUS:$NODEGROUP_STATUS"
        sleep 5;
    done
}

policy_found=1
function policyExists() {
    POLICIES=$(aws iam list-role-policies --role-name $1)
    for entry in $POLICIES; do
        entry=$(echo $entry | cut -d '"' -f 2)
        if [[ $entry == $2 ]]; then
            policy_found=0
            break
        fi
    done
}

function enableCSIDriverForCluster() {
    EKS_ID=$(aws eks describe-cluster --name $CLUSTER_NAME \
    --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
    echo $EKS_ID

    list_open_id_connect_providers=$(aws iam list-open-id-connect-providers | grep $EKS_ID | cut -d "/" -f4)
    echo "list-open-id-connect-providers=$list_open_id_connect_providers"

    eksctl utils associate-iam-oidc-provider --cluster $CLUSTER_NAME --approve

    ROLES=$(aws iam list-roles --query "Roles[*].RoleName")
    match=1
    for entry in $ROLES; do
        entry=$(echo $entry | cut -d '"' -f 2)
        if [[ $entry == "AmazonEKS_EBS_CSI_DriverRole" ]]; then
            match=0
            break
        fi
    done

    #Delete role and detach role policy, if it already exists 
    if [ $match -eq 0 ]; then
        policy_found=1
        policyExists "AmazonEKS_EBS_CSI_DriverRole" "AmazonEBSCSIDriverPolicy";
        echo "policy_found: $policy_found"
        if [ $policy_found -eq 0 ]; then
            aws iam detach-role-policy \
            --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
            --role-name AmazonEKS_EBS_CSI_DriverRole
        fi

        policyExists "AmazonEKS_EBS_CSI_DriverRole" "KMS_Key_For_Encryption_On_EBS_Policy";
        policy_found=1
        echo "policy_found: $policy_found"
        if [ $policy_found -eq 0 ]; then
            aws iam detach-role-policy \
            --policy-arn arn:aws:iam::061512430429:policy/KMS_Key_For_Encryption_On_EBS_Policy \
            --role-name AmazonEKS_EBS_CSI_DriverRole
        fi

        aws iam delete-role --role-name AmazonEKS_EBS_CSI_DriverRole
    fi

    if [ -f ~/aws-ebs-csi-driver-trust-policy.json ]; then
        rm ~/aws-ebs-csi-driver-trust-policy.json
    fi
    FLAGS_2="$(
        cat <<EOF >>~/aws-ebs-csi-driver-trust-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Federated": "arn:aws:iam::$ACCOUNT_ID:oidc-provider/oidc.eks.$REGION.amazonaws.com/id/$EKS_ID"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
            "StringEquals": {
            "oidc.eks.$REGION.amazonaws.com/id/$EKS_ID:aud": "sts.amazonaws.com",
            "oidc.eks.$REGION.amazonaws.com/id/$EKS_ID:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            }
        }
        }
    ]
}
EOF
    )"

    aws iam create-role \
    --role-name AmazonEKS_EBS_CSI_DriverRole \
    --assume-role-policy-document file://"~/aws-ebs-csi-driver-trust-policy.json"  > /dev/null

    aws iam attach-role-policy \
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
    --role-name AmazonEKS_EBS_CSI_DriverRole


    KEY_ARN=$(aws kms list-keys | jq .Keys[0].KeyArn)
    echo $KEY_ARN

    POLICIES=$(aws iam list-policies --query "Policies[*].PolicyName")
    match=1
    for entry in $POLICIES; do
        entry=$(echo $entry | cut -d '"' -f 2)
        if [[ $entry == "KMS_Key_For_Encryption_On_EBS_Policy" ]]; then
            match=0
            break
        fi
    done

    #Delete role and detach role policy, if it already exists 
    if [ $match -eq 0 ]; then
        aws iam delete-policy --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/KMS_Key_For_Encryption_On_EBS_Policy
    fi

    if [ -f ~/kms-key-for-encryption-on-ebs.json ]; then
        rm ~/kms-key-for-encryption-on-ebs.json
    fi
    FLAGS_2="$(
        cat <<EOF >>~/kms-key-for-encryption-on-ebs.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Action": [
            "kms:CreateGrant",
            "kms:ListGrants",
            "kms:RevokeGrant"
        ],
        "Resource": [$KEY_ARN],
        "Condition": {
            "Bool": {
            "kms:GrantIsForAWSResource": "true"
            }
        }
        },
        {
        "Effect": "Allow",
        "Action": [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
        ],
        "Resource": [$KEY_ARN]
        }
    ]
}
EOF
    )"

    KMS_KEY_ARN=$(aws iam create-policy \
    --policy-name KMS_Key_For_Encryption_On_EBS_Policy \
    --policy-document file://~/kms-key-for-encryption-on-ebs.json | jq .Policy.Arn | cut -d '"' -f 2)
    echo $KMS_KEY_ARN

    aws iam attach-role-policy \
    --policy-arn $KMS_KEY_ARN \
    --role-name AmazonEKS_EBS_CSI_DriverRole

    aws eks create-addon --cluster-name $CLUSTER_NAME --addon-name aws-ebs-csi-driver \
    --service-account-role-arn arn:aws:iam::$ACCOUNT_ID:role/AmazonEKS_EBS_CSI_DriverRole

    CSI_DRIVER_ADDON_STATUS=""
    while [[ $CSI_DRIVER_ADDON_STATUS != "ACTIVE" ]]; do
        CSI_DRIVER_ADDON_STATUS=$(aws eks describe-addon --cluster-name $CLUSTER_NAME \
        --addon-name aws-ebs-csi-driver | jq .addon.status | cut -d '"' -f 2)
        echo "CLUSTER ADDON:$CSI_DRIVER_ADDON_STATUS"
        sleep 5;
    done
}

function deleteCluster() {
    aws eks delete-cluster --name $CLUSTER_NAME > /dev/null

    CLUSTER_STATUS=""
    while [[ $CLUSTER_STATUS != "DELETING" ]]; do
        CLUSTER_STATUS=$(aws eks describe-cluster --name $CLUSTER_NAME | jq .cluster.status | cut -d '"' -f 2)
        echo "CLUSTER STATUS:$CLUSTER_STATUS"
        sleep 5;
    done
}

function deleteNodegroup() {
    aws eks delete-nodegroup --cluster-name $CLUSTER_NAME \
    --nodegroup-name $CLUSTER_NAME-nodegroup > /dev/null

    NODEGROUP_STATUS=""
    while [[ $NODEGROUP_STATUS != "DELETING" ]]; do
        NODEGROUP_STATUS=$(aws eks describe-nodegroup --nodegroup-name $CLUSTER_NAME-nodegroup \
        --cluster-name $CLUSTER_NAME|jq .nodegroup.status | cut -d '"' -f 2)
        echo "NODEGROUP STATUS:$NODEGROUP_STATUS"
        sleep 5;
    done
}

banner_info "Step- Validatevars";
validateVars

banner_info "Step- Install eksctl, kubectl";
installTools;

banner_info "Step- Check Cluster exists";
clusterExists=checkClusterExists;

if [[ $clusterExists -eq 0 ]]; then
    echo "Cluster esixts, so stikking role and cluster setup"
else
    banner_info "Step- Prep Cluster Role";
    prepEksClusterRole

    banner_info "Step- Cluster Setup";
    setupCluster
fi

banner_info "Step- Cluster Setup Validation";
validateClusterSetup

banner_info "Steps- Check Cluster NodeGroup exists";
clusterNodegroupExists=checkClusterNodegroupExists;

if [[ $clusterNodegroupExists -eq 0 ]]; then
    echo "Cluster Nodegroup eixts, so stikking cluster nodegroup setup"
else
    banner_info "Step- Prep Nodegroup Role";
    prepNodegroupRole

    banner_info "Step- Cluster Nodegroup Setup";
    setupClusterNodegroup
fi

banner_info "Step- Enable CSI Driver Addon for Cluster";
enableCSIDriverForCluster;
