Creates a bastion host on an existing VPC.
This is useful for cases such as getting access to privatelink Openshift Dedicate clusters.

Steps:
1. Create a new set of ssh keys using `ssh-keygen`
2. Get the id of the VPC to deploy the bastion host on.
3. Run terraform scripts
```
[rcampos@rh-laptop bastion-host]$ tf apply -var 'key_file=/home/rcampos/.ssh/aws-key.pub' -var 'vpc_id=vpc-0bc9e471d4defe4cd'

...

Apply complete! Resources: 9 added, 0 changed, 0 destroyed.

Outputs:

Apply complete! Resources: 9 added, 0 changed, 0 destroyed.

Outputs:

bastion_private_ip = "10.0.22.55"
bastion_public_ip = "34.236.169.174"
vpc_cidr = "10.0.0.0/16"
vpc_id = "vpc-0bc9e471d4defe4cd"
```

4. (TODO) Once the bastion host is made, resources on the VPC can be accessed by running sshuttle.
[rcampos@rh-laptop bastion-host]$ sshuttle --ssh-cmd 'ssh -i ~/.ssh/aws-key' -r ec2-user@34.236.169.174 10.0.0.0/16 -v --dns

For now the easiest way I found to get access to privatelink clusters has been to:
- Copy kubeconfig file into bastion host
- ssh into bastion host
- Install kubectl
https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
- Point kubectl to cluster through the kubeconfig
$ EXPORT KUBECONFIG=$KUBECONFIG_FILE
