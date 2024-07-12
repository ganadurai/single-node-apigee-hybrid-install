#!/bin/bash

set -e

source ./install-functions.sh

function validateEksSetupVars() {

  if [[ -z $CLUSTER_NAME ]]; then
    echo "Environment variable CLUSTER_NAME is not set, please checkout README.md"
    exit 1
  fi

  if [[ -z $NODEGROUP_NAME ]]; then
    echo "Environment variable NODEGROUP_NAME is not set, please checkout README.md"
    exit 1
  fi

  if [[ -z $EKS_REGION ]]; then
    echo "Environment variable EKS_REGION is not set, please checkout README.md"
    exit 1
  fi

  if [[ -z $ACCOUNT_ID ]]; then
    echo "Environment variable ACCOUNT_ID is not set, please checkout README.md"
    exit 1
  fi

  if [[ -z $AWS_ACCESS_KEY_ID ]]; then
    echo "Environment variable AWS_ACCESS_KEY_ID is not set, please checkout README.md"
    #https://stackoverflow.com/questions/21440709/how-do-i-get-aws-access-key-id-for-amazon
    exit 1
  fi

  if [[ -z $AWS_SECRET_ACCESS_KEY ]]; then
    echo "Environment variable AWS_SECRET_ACCESS_KEY is not set, please checkout README.md"
    #https://stackoverflow.com/questions/21440709/how-do-i-get-aws-access-key-id-for-amazon
    exit 1
  fi
}

function installEksSetupTools() {
    #eksctl install
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin
    eksctl version

    #kubectl install
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    kubectl version --client

    #git install
    sudo yum install git

    #yq install
    sudo wget https://github.com/mikefarah/yq/releases/download/v4.28.2/yq_linux_amd64.tar.gz -O - | tar xz && sudo mv yq_linux_amd64 /usr/bin/yq

    #helm install
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
    chmod 700 get_helm.sh
    ./get_helm.sh

    #terraform install
    git clone https://github.com/tfutils/tfenv.git ~/.tfenv
    mkdir ~/bin
    ln -s ~/.tfenv/bin/* ~/bin/
    tfenv install 1.8.4
    tfenv use 1.8.4
    terraform --version
}

function createVPCForEKSCluster() {
    if [[ -z $VPC_ID ]]; then
        #echo "Deleting cloudformation stack my-eks-vpc-stack"
        #aws cloudformation delete-stack --stack-name my-eks-vpc-stack
        #echo "Sleeping for 15 secs for the vpc to be cleaned"
        #sleep 15;
        RAND_VAL=$RANDOM
        aws cloudformation create-stack \
            --region $EKS_REGION \
            --stack-name my-eks-vpc-stack-$RAND_VAL  \
            --template-url https://s3.us-west-2.amazonaws.com/amazon-eks/cloudformation/2020-10-29/amazon-eks-vpc-private-subnets.yaml
        echo "Sleeping for 15 secs for the vpc to be created"
        sleep 15;
        VPC_ID=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=my-eks-vpc-stack-$RAND_VAL-VPC \
                    --query "Vpcs[0].VpcId" | cut -d '"' -f 2)
        echo "VPC_ID=$VPC_ID"
    fi
}

function prepEksClusterRole() {
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

cluster_exists=1
function checkClusterExists() {
    CLUSTERS=$(aws eks list-clusters --query "clusters")

    if [ ${#CLUSTERS[@]} -gt 0 ]; then
        for entry in $CLUSTERS; do
            entry=$(echo $entry | cut -d '"' -f 2)
            if [[ $entry == "$CLUSTER_NAME" ]]; then
                cluster_exists=0
                break
            fi
        done
    fi
}

function setupCluster() {
    sleep 10;
    SUBNETS=$(aws ec2 describe-subnets --filter Name=vpc-id,Values=$VPC_ID | \
                jq -r '[.Subnets[].SubnetId] | join(",")')
    
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
    aws eks update-kubeconfig --region $EKS_REGION --name $CLUSTER_NAME
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

nodegroup_exists=1
function checkClusterNodegroupExists() {
    NODEGROUPS=$(aws eks list-nodegroups --cluster-name $CLUSTER_NAME \
        --query "nodegroups[0]")
    if [ ${#NODEGROUPS[@]} -gt 0 ]; then
        entry=$(aws eks list-nodegroups --cluster-name $CLUSTER_NAME \
        --query "nodegroups[0]" | cut -d '"' -f 2)
        if [[ $entry == "$CLUSTER_NAME-nodegroup" ]]; then
            nodegroup_exists=0
            break
        fi
    fi
}

function setupClusterNodegroup() {
    SINGLE_SUBNET=$(aws ec2 describe-subnets --filter Name=vpc-id,Values=$VPC_ID | jq .Subnets[0].SubnetId | cut -d '"' -f 2)
    echo $SINGLE_SUBNET

    aws eks create-nodegroup --cluster-name $CLUSTER_NAME \
    --nodegroup-name $CLUSTER_NAME-nodegroup \
    --subnets $SINGLE_SUBNET \
    --node-role arn:aws:iam::$ACCOUNT_ID:role/myAmazonEKSNodeRole \
    #--disk-size 20 \
    #--instance-types 't3.xlarge' \
    --disk-size 8 \
    --instance-types 't2.micro' \
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

role_policy_found=1
function rolePolicyExists() {
    #POLICIES=$(aws iam list-role-policies --role-name $1)
    ROLES=$(aws iam list-entities-for-policy --policy-arn $1 --query "PolicyRoles[*].RoleName")
    for entry in $ROLES; do
        entry=$(echo $entry | cut -d '"' -f 2)
        if [[ $entry == $2 ]]; then
            role_policy_found=0
            break
        fi
    done
}

policy_found=1
function policyExists() {
    POLICIES=$(aws iam list-policies --query "Policies[*].PolicyName")
    for entry in $POLICIES; do
        entry=$(echo $entry | cut -d '"' -f 2)
        if [[ $entry == $1 ]]; then
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
        role_policy_found=1
        rolePolicyExists "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy" "AmazonEKS_EBS_CSI_DriverRole";
        if [ $role_policy_found -eq 0 ]; then
            aws iam detach-role-policy \
            --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
            --role-name AmazonEKS_EBS_CSI_DriverRole
        fi

        role_policy_found=1
        rolePolicyExists "arn:aws:iam::$ACCOUNT_ID:policy/KMS_Key_For_Encryption_On_EBS_Policy" "AmazonEKS_EBS_CSI_DriverRole";
        if [ $role_policy_found -eq 0 ]; then
            aws iam detach-role-policy \
            --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/KMS_Key_For_Encryption_On_EBS_Policy \
            --role-name AmazonEKS_EBS_CSI_DriverRole
        fi

        policy_found=1
        policyExists "KMS_Key_For_Encryption_On_EBS_Policy"
        if [ $policy_found -eq 0 ]; then
            aws iam delete-policy --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/KMS_Key_For_Encryption_On_EBS_Policy
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
            "Federated": "arn:aws:iam::$ACCOUNT_ID:oidc-provider/oidc.eks.$EKS_REGION.amazonaws.com/id/$EKS_ID"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
            "StringEquals": {
            "oidc.eks.$EKS_REGION.amazonaws.com/id/$EKS_ID:aud": "sts.amazonaws.com",
            "oidc.eks.$EKS_REGION.amazonaws.com/id/$EKS_ID:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
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

    CLUSTER_STATUS="DELETING"
    while [[ $CLUSTER_STATUS == "DELETING" ]]; do
        CLUSTER_STATUS=$(aws eks describe-cluster --name $CLUSTER_NAME | jq .cluster.status | cut -d '"' -f 2)
        echo "CLUSTER STATUS:$CLUSTER_STATUS"
        sleep 5;
    done

    #Deletes loadbalancer
    LB_NAME=$(aws elb describe-load-balancers --query "LoadBalancerDescriptions[0].LoadBalancerName" \
                | cut -d '"' -f 2)
    aws elb delete-load-balancer --load-balancer-name $LB_NAME

    NAT_GW_IDS=$(aws ec2 describe-nat-gateways --filter Name=vpc-id,Values=$VPC_ID --query "NatGateways[*].NatGatewayId")
    for entry in $NAT_GW_IDS; do
        entry=$(echo $entry | cut -d '"' -f 2)
        if [[ $entry != "[" ]] && [[ $entry != "]" ]]; then
            aws ec2 delete-nat-gateway --nat-gateway-id $entry
        fi
    done
    sleep 5;

    #Delete VPC from console
    aws ec2 delete-vpc --vpc-id $VPC_ID
    
    #Deletes CF 
    aws cloudformation delete-stack --stack-name my-eks-vpc-stack

    # Delete hybrid-launcher (t2.micro EC2 Instance), Loadbalanacer, NAT Gateway, Release Elastic IPs
}

function deleteNodegroup() {
    aws eks delete-nodegroup --cluster-name $CLUSTER_NAME \
    --nodegroup-name $CLUSTER_NAME-nodegroup > /dev/null

    NODEGROUP_STATUS="DELETING"
    while [[ $NODEGROUP_STATUS == "DELETING" ]]; do
        NODEGROUP_STATUS=$(aws eks describe-nodegroup --nodegroup-name $CLUSTER_NAME-nodegroup \
        --cluster-name $CLUSTER_NAME|jq .nodegroup.status | cut -d '"' -f 2)
        echo "NODEGROUP STATUS:$NODEGROUP_STATUS"
        sleep 5;
    done
}

function eksPrepAndInstall() {

    banner_info "Step- EKS Install Validatevars ";
    validateEksSetupVars

    banner_info "Step- Check Cluster exists";
    checkClusterExists;

    if [[ $cluster_exists -eq 0 ]]; then
        echo "Cluster eixts, so skipping role and cluster setup"
    else
        banner_info "Step- Setting VPC for EKS cluster"
        createVPCForEKSCluster

        banner_info "Step- Prep Cluster Role";
        prepEksClusterRole

        banner_info "Step- Cluster Setup";
        setupCluster
        sleep 10;
    fi

    banner_info "Step- Cluster Setup Validation";
    validateClusterSetup

    banner_info "Steps- Check Cluster NodeGroup exists";
    checkClusterNodegroupExists;

    if [[ $nodegroup_exists -eq 0 ]]; then
        echo "Cluster Nodegroup eixts, so stikking cluster nodegroup setup"
    else
        banner_info "Step- Prep Nodegroup Role";
        prepNodegroupRole

        banner_info "Step- Cluster Nodegroup Setup";
        setupClusterNodegroup
    fi

    banner_info "Step- Enable CSI Driver Addon for Cluster";
    enableCSIDriverForCluster;

    banner_info "Complete EKS Cluster Setup";
}