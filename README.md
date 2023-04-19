# Cloud init in VMware vSphere 7.0

## Configure the cloud-init template

This tutorial is based on an Ubuntu 22.04 cloud image.

1. Deploy OVF Template

    URL : cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.ova

2. Change OVF environment transport

    Go to Menu > VMs and Templates > My VM > Configure > vApp Options

    Click on edit and disable the vApp Options feature.

3. Convert VM to Template

    The last step is to clone your virtual machine to a template in order to allow you to use it multiple times.

    In order to do that, you can go to Menu > VMs and Templates > My VM > Actions > Template and click on Convert To Template.

## Cloud init

Cloud-init is the industry standard multi-distribution method for cross-platform cloud instance initialization. During boot, cloud-init identifies the cloud it is running on and initializes the system accordingly.

Public and private cloud providers provide tools to allow the deployment of VMs cloud-init capable. For VMware, it is done by setting advanced params on the virtual machine which will be passed to the guest OS at startup.


## Usage

### Clone repository

    git clone 

### Dependencies

The only dependency you need is the VMware.PowerCLI, you can install it by running this command :

    Install-Module VMware.PowerCLI -Scope CurrentUser

### Files

You will have to create a folder for your specific machine deployment at the main script level. The folder name and the VM name must be the same. The files userdata.yml and metadata.yml must exists even if they are empty.

#### Meta-data file: metadata.yml

This file contain instance data provided by the hosting company :

- Hostname
- Authorization information (ssh public keys)
- Network information, with OS specific confgiuration, Netplan for ubuntu
- Instance-id
- Tags

#### User-data file: userdata.yml

This file contains information on more ephemeral specifications, it enables automation and integration :

- Add Packages and Upgrade
- Set Hostname
- Add Users and Groups
- Add SSH Keys
- Partition Disks
- Run Arbitrary Code
- Timezone / Locale
- Mirror Selection

### Set environnement variables

You will have to set to environment variables : $Env:VIUser and $Env:VIPassword.

    $Env:VIUser="test"
    $Env:VIPassword="test"

### Run script

The deploy script takes multiple mandatory arguments:

- Server: vCenter server IP or FQN,
- Template: cloud image template previously deployed,
- Name: Virtual Machine name
- Folder: the VM folder name
- ResourcePool: VMHost, Cluster, ResourcePool, or VApp objects

The following parameters are not mandatory :

- NumCPU: Number of CPU
- MemoryGB: Memory in GB
- DiskGB: Disk in GB
- Portgroup: Network name to connect VM

### Examples

Here is some examples to lauch the script in your Powershell terminal :

    ./deploy.ps1 -Server vcenter.test.local -Template ubuntu-jammy-cloudimg -Name example.test.local -Folder cloud-init -ResourcePool cluster01

    ./deploy.ps1 -Server vcenter.test.local -Template ubuntu-jammy-cloudimg -Name example.test.local -Folder cloud-init -ResourcePool cluster01 -NumCPU 6 -MemoryGB 8 -DiskGB 16 -Portgroup "pg-pedago-internet"
    
    ./deploy.ps1 -Server vcenter.test.local -Template ubuntu-jammy-cloudimg -Name example.test.local -Folder cloud-init -ResourcePool cluster01 -NumCPU 6 -Portgroup "pg-pedago-internet"

## Ressources

- [An Introduction to Cloud-Config Scripting - Digital Ocean](https://www.digitalocean.com/community/tutorials/an-introduction-to-cloud-config-scripting)

- [Cloud Instance Initialisation with cloud-init - Canonical](https://pages.ubuntu.com/rs/066-EOV-335/images/CloudInit_Whitepaper.pdf)

- [VMware cloud-init integration](https://cloudinit.readthedocs.io/en/latest/topics/datasources/vmware.html)
