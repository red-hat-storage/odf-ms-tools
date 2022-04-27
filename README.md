# Managed OpenShift Data Foundation

## About

The OpenShift Data Foundation managed service is provisioned using the ROSA command line utilities. The `rosa create service` command is mechanism used for provisioning. Provisioning instantiates a _service cluster_ that provides storage to _application clusters_. Service clusters are wholly managed by Red Hat SRE teams, users cannot be created on them, and they cannot be configured with customer provided identity provider.

Application clusters are clusters provisioned with `rosa create cluster` for the purpose of running customer or ISV applications. In order for an application cluster to be able to consume storage from a provisioned ODF service cluster, the ODF consumer adddon needs to be installed with `rosa install addon`.

#### Application cluster testing status by version

|Version|Status|
|---------------------------|------|
| 4.10 | Ready |
| 4.8 | In-progress|

### Resources

At the onset OpenShift Data Foundation service clusters are of a fixed size, and provide 20TB of capacity after replication. Both smaller initial sizes, and the ability to scale them will come later. The service cluster is a standard ROSA cluster with the following exceptions:

* Worker instance type is fixed (m5.4xlarge)
* Worker quantity is fixed (3)
* Multi-AZ
* 15x 4TB gp2 EBS volumes will be created (5x per AZ)

### Quota

A Red Hat account with appropriate entitlements is a required to create ODF service clusters, or install the ODF consumer addon the. To request entitlements, please provide the output of `rosa whoami`

## Prerequisites

### ROSA Command Line Utility

The ROSA command line utility must be version 1.2.0 or later in order to be able to execute the `rosa create service` sub commands. The latest version can be downloaded [here](https://mirror.openshift.com/pub/openshift-v4/clients/rosa/latest/).

### AWS Virtual Private Cloud (VPC)

Currently, testing has been limited to configurations where the ODF service cluster and application cluster reside in the same VPC. There are two primary ways of meeting this requirement:

1. Create a multi-az application cluster first, and create the service cluster in the resulting VPC
2. Create a VPC with all the requisite AWS networking resources

The first is the most straightforward because all the required AWS networking resources that are required for a ROSA cluster will be provisioned for you. The second option is primarily for teams who are familiar with the AWS networking resources required for a ROSA cluster, and have existing automation in place for provisioning (eg. Ansible playbooks, Cloud Foundation templates, etc).

### ODF Security Group

> **_NOTE:_** This must be done before `rosa create service`

Security group name must be created in the target VPC with the name `odf-sec-group`. Inbound rules need to be added for the following ports / port ranges. The rule type should be "Custom TCP", and the source should be the CIDR of the VPC (eg. 10.0.0.0/16). This will enable any worker nodes from any application cluster running in the VPC to initiate communication with the service cluster.

|Rule Type|Port|Description|
|---------|----|-----------|
|Custom TCP|6789|ODF Ceph MON v1|
|Custom TCP|3300|ODF Ceph MON v2|
|Custom TCP|6800-7300|ODF Ceph OSD|
|Custom TCP|9283|ODF Ceph MGR|
|Custom TCP|31659|ODF Provisioner API|

For supportability, it is important that these rules be part of a distinct security group.

## Provisioning ODF Service

### Generate RSA key pair

> **_NOTE:_** Not to be confused with SSH credentials.

A public/private key pair needs to be generated to make use of the ODF Managed Service. The public key is passed to the `rosa create service` command that provisions the service cluster. The private key is used to generate tickets for application clusters that will consume storage from the service cluster. You'll want to store the private key somewhere safe and secure since you will need it to generate tickets for future application clusters.

```
openssl genrsa -out key.pem 4096
openssl rsa -in key.pem -out pubkey.pem -outform PEM -pubout
```

### Create service cluster

> **_NOTE:_** At least three subnets must be provided, each in a distinct AWS Availability Zone

A list of subnets will need to be collected in order to provision a service cluster, they are passed to the `rosa create service` command via the `--subnet-ids` parameter as a comma seperated list.

```
export SERVICE_CLUSTER_NAME=odf-ms
# example subnets
export SUBNET_IDS="10.0.0.0/24,10.0.1.0/24,10.0.1.0/24"

rosa create service --type ocs-provider \
  --name $SERVICE_CLUSTER_NAME \
  --size 20 \
  --onboarding-validation-key "$(cat pubkey.pem | sed 's/-.* PUBLIC KEY-*//')" \
  --subnet-ids
```

## Consuming ODF Service

> **_NOTE:_** Check the version of the application cluster against the table [here](#application-cluster-testing-status-by-version)

### Download ticket generation script

```
curl -O https://gist.githubusercontent.com/mmgaggle/18123123a37ca0a7dd570502d0bfe441/raw/c97bbd8925cacc3419c3714ca19d0bf1691ab01a/ticketgen.sh
```

### Install ODF Consumer addon in application cluster

```
export APPLICATION_CLUSTER_NAME=mycluster
TICKET=$(./ticketgen.sh key.pem)
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
