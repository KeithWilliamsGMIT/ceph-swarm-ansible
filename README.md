# Ceph Swarm Ansible

This repository shows how to setup a Ceph cluster running in Docker Swarm using Ansible to automate the task. This reposioty is heavily based on [ceph-swarm](https://github.com/sepich/ceph-swarm) by sepich. There are other tools and methods of creating a Ceph cluster. This repository was created to learn new technologies and to experiment running Ceph in Docker Swarm.

### Getting Started

The first step to getting started is to clone the repository:

```
git clone https://github.com/KeithWilliamsGMIT/ceph-swarm-ansible
```

We can use Vagrant to quickly spin up a small cluster of virtual machines loaclly to deploy Ceph to. The same steps should work in a cloud environment or with any computers connected by a network. We use Vagrant to create two Ubuntu 18.04 virtual machines by default with the names `node(n)` and with IPv4 addresses of `192.168.2.(n+1)` on a private network through the `eth1` internet interface. To create this cluster first install Vagrant and then follow the commands:

```
cd vagrant
vagrant up
```

This may take some time when first running it as the Vagrant box will need to be downloaded but subsequent runs should be quicker. These virtual machines are provisioned with Ansible to update `pip`. It also generates an Ansible inventory file required by Ansible which saves us from manually writting one ourselves. Once started you can ssh into `node1` using the command:

```
vagrant ssh node1
```

These virtual machines also have a virtual hard disk attached which replicate secondary storage and is used by Ceph. These files are created in the `vagrant/disks` directory and are ignored by Git.

Once the Vagrant cluster is setup we can start deploying the Ceph cluster to them. First install Ansible and then we can use two existing Ansible roles to install Docker and initialise a Docker Swarm. These roles are defined in the `requirements.yml` file and will be installed to `~/.ansible/roles/` by default using the below command:

```
ansible-galaxy install -r requirements.yml
```

We can install [Docker](https://docs.docker.com/install/) on all the virtual machines now using the `install-docker.yml` playbook as shown below:

```
ansible-playbook -i ../vagrant/.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory install-docker.yml
```

Similarly, to initialise a Docker Swarm between this cluster of virtual machines we can run the `initialize-swarm.yml` playbook. Note that we set extra variables to override some defaults in the playbook. We want to skip everything except the actual initialisation of Docker Swarm. Also, note that when using this playbook with a cluster of VMs created with Vagrant we need to set another variable to override the default network interface and instead use the private network which is `eth1`.
```
ansible-playbook -i ../vagrant/.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory initialize-swarm.yml --extra-vars="{'skip_engine': 'True', 'skip_group': 'True', 'skip_docker_py': 'True', 'docker_swarm_interface': 'eth1'}"
```

Finally, we can deploy the stack containing all of out Ceph services, including managers, monitors, OSDs and metadata servers, to Docker Swarm using the `deploy-storage.yml` playbook. Again, similar to what we did when initialising Docker Swarm, we explicitly set the network interface as the default interface on the virtual machines don't point to the private network where they have unique IP addresses.

```
ansible-playbook -i ../vagrant/.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory deploy-storage.yml --extra-vars="{'ceph_interface': 'eth1'}" --ask-vault-pass --ask-sudo-pass
```

The `--ask-vault-pass` flag will prompt you for the vault password to access sensitive data. A default password used in this case, for demostraion purposes in `password`. This playbook creates a directory called `out` by default where a number of files are output to. This directory is ignored by Git.

### Does it work?

Once you followed the above steps we can check if all the services are running as expected by sshing into `node1` as thats the docker manager by default.

```
ubuntu:~/ceph-swarm-ansible/playbooks$ vagrant ssh node1
...
vagrant@node1:~$ sudo docker service ls
ID                  NAME                MODE                REPLICAS            IMAGE                           PORTS
k2h00xetv8e6        storage_mds         replicated          2/2                 ceph/daemon:latest
b8b0ic2eq8ru        storage_mgr         replicated          1/1                 ceph/daemon:latest
p4ao16o126w1        storage_mon         global              1/1                 ceph/daemon:latest
wrdzdyw2u0fs        storage_osd         global              2/2                 ceph/daemon:latest
```

We can check if the files are accessible from both nodes by sshing into `node1` and creating a file in the `/mnt/ceph` directoy. Then ssh into `node2` and checking if the changes are reflected in the same folder.

```
ubuntu:~/ceph-swarm-ansible/playbooks$ vagrant ssh node1
...
vagrant@node1:~$ touch /mnt/ceph/test
vagrant@node1:~$ ls -al /mnt/ceph/
-rw-r--r-- 1 root root    0 Jun  7 19:48 test
vagrant@node1:~$ exit

...

ubuntu:~/ceph-swarm-ansible/playbooks$ vagrant ssh node2
...
vagrant@node2:~$ ls -al /mnt/ceph/test
vagrant@node2:~$ ls -al /mnt/ceph/
-rw-r--r-- 1 root root    0 Jun  7 19:48 test
vagrant@node2:~$ exit
```

### Contributing

Any contribution to this repository is appreciated, whether it is a pull request, bug report, feature request, feedback or even starring the repository. Some potential areas that need further refinement are:

+ Hardening of playbooks
+ Making playbooks completely idempotent
+ Improved error handling
+ Publish to Ansible Galaxy
+ Documentation

### Conslusion
This repository demonstates a number of different technologies and how then can be used together. Vagrant is a powerful tool to quickly and cheaply simulate cloud environments locally which is required to test this repository. Running Ceph within Docker Swarm was an interesting experiment and seems to work as expected. Finally, running all of these commands manually everytime we need to deploy Ceph would be extremely time consuming and so Ansible is quite useful in this case and works well with Vagrant.
