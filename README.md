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

Please ensure you have sufficient service quota in AWS. See [ROSA Required AWS Service Quotas](https://docs.openshift.com/rosa/rosa_install_access_delete_clusters/rosa_getting_started_iam/rosa-required-aws-service-quotas.html). With Managed ODF, the minimum General Purpose SSD (gp2) volume storage should be at least 75.

### Quota

A Red Hat account with appropriate entitlements is a required to create ODF service clusters, or install the ODF consumer addon the. To request entitlements, please provide the output of:

```
rosa whoami
```

To verify entitlements, you can run the following. Look for ocs-provider and ocs-consumer addons, if they are not present, you do not have the appropriate entitlements.

```
rosa list addons
```

## Prerequisites

### ROSA Command Line Utility

The ROSA command line utility must be version 1.2.0 or later in order to be able to execute the `rosa create service` sub commands. The latest version can be downloaded [here](https://mirror.openshift.com/pub/openshift-v4/clients/rosa/latest/).

### AWS Virtual Private Cloud (VPC)

Currently, testing has been limited to configurations where the ODF service cluster and application cluster reside in the same VPC. This repo includes Terraform templates to create a multiple availability zone VPC with all the requisite AWS networking resources to support ODF service clusters and application clusters. The application clusters can be single or multi-az.

```
cd terraform
terraform init
terraform plan
terraform apply
```

## Provisioning ODF Service

### Email notifications

```
EMAIL="jane@example.org"
```

### Service cluster validation key

```
VALIDATION_KEY=$(aws kms get-public-key --key-id alias/odf --output text  --query PublicKey)
echo ${VALIDATION_KEY}
```
### Service cluster subnets

> **_NOTE:_** A public and private subnet is required per availability zone

> **_NOTE:_** A private subnet is required per availability zone for privatelink clusters

A list of subnets will need to be collected in order to provision a service cluster, they are passed to the `rosa create service` command via the `--subnet-ids` parameter as a comma seperated list.

```
# example subnets
export SUBNET_IDS="subnet-abc,subnet-def,subnet-ghi,subnet-jkl,subnet-mno,subnet-pqr"
```

### Create service

As early as next week, `rosa create service` will create the cluster with the `ocs-provisioner` addon preinstalled. This will also automatically add the `odf-sec-group` security group to service cluster instances via the Machine API.

```
rosa create service \
  --type ocs-provider \
  --name odf-service \
  --size 20 \
  --unit  Ti \
  --subnet-ids ${SUBNET_IDS} \
  --notification-email-0 "${EMAIL}" \
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


rosa create operator-roles \
  --cluster apps \
  --mode auto \
  --yes
  
rosa create oidc-provider \
  --cluster apps \
  --mode auto \
  --yes
```

### Generate onboarding ticket

```
TICKET=$(bash ./ticketgen.sh)
echo ${TICKET}
```

### Find a woker node IP on service cluster

```
aws ec2 describe-instances \
  --region 'us-west-2' \
  --filters "Name=instance.group-name,Values=odf-sec-group" \
  --query "Reservations[*].Instances[*].[PrivateIpAddress]" \
  --output text

ENDPOINT="<insert ip address>"
```

### Install ODF Consumer addon in application cluster

```
rosa install addon ocs-consumer \
  -c apps \
  --size 1 \
  --onboarding-ticket $TICKET \
  --notification-email-0 "${EMAIL}" \
  --storage-provider-endpoint ${ENDPOINT}:31659 \
  --yes  
```

### Check addon installation status

```
rosa list addons -c $APPLICATION_CLUSTER_NAME
```
