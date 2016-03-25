---
layout: default
title: "Run MacPatch with Vagrant"
---


Use this Vagrant file to build and configure a MacPatch server on Ubuntu in a VirtualBox. This is not for production environments, but is helpful when evaluating MacPatch.

Vagrant official website: [https://www.vagrantup.com](https://www.vagrantup.com)

## Setup
1. Install [Vagrant](https://docs.vagrantup.com/v2/installation/) and [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
2. Clone the repo `git clone https://github.com/SMSG-MAC-DEV/MacPatch-Vagrant.git`
3. `cd` into the project directory
4/ Start the VM by running `vagrant up`

You now have a MacPatch sever. But you will still need to follow the Configure MacPatch - Admin Console section of the documentation to complete the setup.

## Possible issues with an SSL proxy
If your are behind an SSL proxy you may encounter errors during the setup and build process. Below are workarounds that I'm aware of.

### Vagrant
Vagrant may run into certificate errors when attempting to download boxes. In some cases adding `--insecure` to the command is enough, but in some case you may need to download and add the box manually.

	cd /tmp/
	curl -O --insecure https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box
	vagrant box add "ubuntu/trusty64" /tmp/trusty-server-cloudimg-amd64-vagrant-disk1.box
	rm /tmp/trusty-server-cloudimg-amd64-vagrant-disk1.box
    
### PIP
You may see certificate errors from pip commands in the bootstrap.sh provisioning script. To workaround this, copy your site's certificate into the project directory. Then modify the file `bootstrap-scripts/bootstrap.sh` and add `--cert /vagrant/mycert.crt` to the pip commands.

### Github
If git complains about certificates, open `bootstrap-scripts/bootstrap.sh` and uncomment the following line: `git config --global http.sslverify false`

## Other possible issues
### VirtualBox DHCP error

If you see the following error:

	A host only network interface you're attempting to configure via DHCP
	already has a conflicting host only adapter with DHCP enabled. The
	DHCP on this adapter is incompatible with the DHCP settings. Two
	host only network interfaces are not allowed to overlap, and each
	host only network interface can have only one DHCP server. Please
	reconfigure your host only network or remove the virtual machine
	using the other host only network.
    
Here is the fix `VBoxManage dhcpserver remove --netname HostInterfaceNetworking-vboxnet0` You can read more about it here [https://github.com/mitchellh/vagrant/issues/3083](https://github.com/mitchellh/vagrant/issues/3083)
