# Azure Recovery CLI Robot
This example will implement Azure CLIs to restore a backup VM to a new VM. Here provide a friendly Python UI to run a Ansible playbook to control the RC robot to automatically restore a snapshot from Azure backup vault to a new resource group and presenting detailed processes for users.

# System
- Linux Centos 7.6
- Azure Cloud

# IaC
- Ansible 2.7.5
- Perl v5.30.2
- Python 2.7
- Azure CLI
- Bourne Shell

# Machanism
- Timeout: terminate the usual long run process by Azure CLI
- Redo: to prevent the processes have not populated to the Azure cloud for some exceptions
- Result Handler: handle the unknow response return from Azure CLI
- Error Hander: handle the unknow error caused by Azure CLI

# RUN
./go.py or python go.py

# References
- https://docs.microsoft.com/en-us/azure/backup/tutorial-restore-disk
- https://docs.microsoft.com/en-us/azure/media-services/previous/media-services-cli-create-and-configure-aad-app
- https://docs.bitnami.com/azure/faq/administration/install-az-cli/
- https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
