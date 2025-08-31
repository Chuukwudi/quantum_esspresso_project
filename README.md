# python_dev_container

When using devcontainers, if you wish to use git inside the devcontainer, see https://code.visualstudio.com/remote/advancedcontainers/sharing-git-credentials#_using-ssh-keys for instructions on how to allow the devcontainer to access your local git credentials.

template repo for python dev container


If deploying lambda via docker, to troubleshoot and explor the file system, you can use the following command:

```bash
docker run -it --entrypoint /bin/bash <image_name>
```
or

```bash
docker run -it --entrypoint /bin/sh <image_name>
```
This exposes the shell so you can do/view whatever you want in the container.


## Command Sequence for Terraform Deployment

The following commands represent a standard Terraform workflow for infrastructure deployment:

```bash
cd IoC
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```
