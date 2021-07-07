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
- Timeout: terminate the unusual long run process by Azure Cli
- Redo: to prevent the processes have not populated to the Azure cloud for some exceptions
- Exception: handle the exceptions when running the az Cli and code
- Result Handler: handle the unknow response return from Azure Cli
- Error Hander: handle the unknow error caused by Azure Cli

# RUN
./go.py or python go.py

# References
- https://docs.microsoft.com/en-us/azure/backup/tutorial-restore-disk
- https://docs.microsoft.com/en-us/azure/media-services/previous/media-services-cli-create-and-configure-aad-app
- https://docs.bitnami.com/azure/faq/administration/install-az-cli/
- https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
