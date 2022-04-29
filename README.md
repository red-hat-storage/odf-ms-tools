# Managed OpenShift Data Foundation

## About

The OpenShift Data Foundation managed service is provisioned using the ROSA command line utilities. The `rosa create service` command is mechanism used for provisioning. Provisioning instantiates a _service cluster_ that provides storage to _application clusters_. Service clusters are wholly managed by Red Hat SRE teams, users cannot be created on them, and they cannot be configured with a customer provided identity provider.

Application clusters are clusters provisioned with `rosa create cluster` for the purpose of running customer or ISV applications. In order for an application cluster to be able to consume storage from a provisioned ODF service cluster, the ODF consumer adddon needs to be installed with `rosa install addon`.

#### Application cluster testing status by version

|Version|Status|
|---------------------------|------|
| 4.10 | Ready |
| 4.8 | In-progress|

### Resources

At the onset OpenShift Data Foundation service clusters are of a fixed size, and provide 20TB of usable capacity after replication. Both smaller initial sizes, and the ability to scale them will come later. The service cluster is a standard ROSA cluster with the following exceptions:

* Worker instance type is fixed (m5.4xlarge)
* Worker quantity is fixed (3)
* Multi-AZ
* 15x 4TB gp2 EBS volumes will be created (5x per AZ)

### Quota

A Red Hat account with appropriate entitlements is a required to create ODF service clusters, or install the ODF consumer addon the. To request entitlements, please provide the output of `rosa whoami`

To verify entitlements, you can run the following (look for ocs-provider and ocs-consumer addons)

```
rosa list addons
```

## Prerequisites

### ROSA Command Line Utility

The ROSA command line utility must be version 1.2.0 or later in order to be able to execute the `rosa create service` sub commands. The latest version can be downloaded [here](https://mirror.openshift.com/pub/openshift-v4/clients/rosa/latest/).

### AWS Virtual Private Cloud (VPC)

Currently, testing has been limited to configurations where the ODF service cluster and application cluster reside in the same VPC. This repo includes Terraform templates to create multiple availability zone VPC with all the requisite AWS networking resources to support ODF service clusters and application clusters. The application clusters can be single or multi-az.

```
cd terraform
terraform init
terraform plan
terraform apply
```

## Provisioning ODF Service

### Service cluster validation key

```
VALIDATION_KEY=$(aws kms get-public-key --key-id alias/odf --output text  --query PublicKey 
```
### Service cluster subnets

> **_NOTE:_** A public and private subnet is required per availability zone
> **_NOTE:_** A private subnet is required per availability zone for privatelink clusters

A list of subnets will need to be collected in order to provision a service cluster, they are passed to the `rosa create service` command via the `--subnet-ids` parameter as a comma seperated list.

```
# example subnets
export SUBNET_IDS="subnet-abc,subnet-def,subnet-ghi,subnet-jkl,subnet-mno,subnet-pqr"
```

### Create service cluster

```
REGION=us-west-2
rosa create cluster \
  --cluster-name odf-service \
  --subnet-ids ${SUBNET_IDS} \
  --machine-cidr 10.0.0.0/16 \
  --region ${REGION} \
  --version=4.10.10 \
  --multi-az \
  --compute-nodes 3 \
  --compute-machine-type m5.4xlarge \
  --sts \
  --yes

rosa create operator-roles \
  --cluster odf-service \
  --mode auto \
  --yes
  
rosa create oidc-provider \
  --cluster odf-service \
  --mode auto \
  --yes
```
### Install `ocs-provider` addon

```
rosa install addon ocs-provider \
  -c odf-service \
  --size 20 \
  --unit  Ti \
  --onboarding-validation-key ${VALIDATION_KEY}
```

### Check addon installation status

```
rosa list addons -c $APPLICATION_CLUSTER_NAME
```

### Create service

As early as next week, `rosa create service` will create the cluster with the `ocs-provisioner` addon preinstalled.

```
rosa create service \
  --type ocs-provider \
  --name odf-service \
  --size 20 \
  --unit  Ti \
  --subnet-ids ${SUBNET_IDS} \
  --onboarding-validation-key ${VALIDATION_KEY}

rosa create operator-roles \
  --cluster odf-service \
  --mode auto \
  --yes
  
rosa create oidc-provider \
  --cluster odf-service \
  --mode auto \
  --yes
```

## Consuming ODF Service

> **_NOTE:_** Check the version of the application cluster against the table [here](#application-cluster-testing-status-by-version)

### Create application cluster

> **_NOTE:_** A cluster with workers in a single availability zone can be created by omiting `--multi-az`

```
rosa create cluster \
  --cluster-name apps \
  --subnet-ids ${SUBNET_IDS} \
  --machine-cidr 10.0.0.0/16 \
  --region us-west-2 \
  --version=4.10.10 \
  --multi-az \
  --compute-nodes 3 \
  --compute-machine-type m5.4xlarge \
  --sts \
  --yes

### Generate onboarding ticket

```
TICKET=$(bash ./ticketgen.sh)
```

### Install ODF Consumer addon in application cluster

```
export APPLICATION_CLUSTER_NAME=mycluster
rosa install addon ocs-consumer \
  -c $APPLICATION_CLUSTER_NAME \
  -size=1 \
  --onboarding-ticket=$TICKET \
  --storage-provider-endpoint=${ANY_PROVIDER_CLUSTER_WORKER_NODE_IP}:31659
```

### Check addon installation status

```
rosa list addons -c $APPLICATION_CLUSTER_NAME
```
