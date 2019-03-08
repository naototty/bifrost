# memo for vagrant up bifrost and work


## before vagrant up

vagrant plugin install vagrant-vbguest
vagrant plugin install vagrant-sshfs


## vagrant env. infomation

vagrant up 後の作業ログを記載する

* eth0 << nat nic >>



eth1 に libvirt bridgeを作って、検証用のvmを起動する (qemu)

```bash
[vagrant@localhost ~]$ ip address list
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN group default qlen 1000
    link/ether 52:54:00:c0:42:d5 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global noprefixroute dynamic eth0
       valid_lft 81867sec preferred_lft 81867sec
    inet6 fe80::5054:ff:fec0:42d5/64 scope link
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN group default qlen 1000
    link/ether 08:00:27:64:48:52 brd ff:ff:ff:ff:ff:ff
    inet 192.168.99.10/24 brd 192.168.99.255 scope global noprefixroute eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe64:4852/64 scope link
       valid_lft forever preferred_lft forever
4: eth2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN group default qlen 1000
    link/ether 08:00:27:d5:35:3f brd ff:ff:ff:ff:ff:ff
    inet 192.168.201.58/22 brd 192.168.203.255 scope global noprefixroute dynamic eth2
       valid_lft 81867sec preferred_lft 81867sec
    inet6 fe80::a00:27ff:fed5:353f/64 scope link
       valid_lft forever preferred_lft forever
```


## after vagrant done.

vagrant ssh login from Mac laptop

```bash
vagrant ssh
```

checking generated file openrc

```bash
[vagrant@localhost ~]$ cat openrc
#!/usr/bin/env bash

# WARNING: This file is managed by bifrost.
export IRONIC_URL=http://localhost:6385
export OS_AUTH_TOKEN='fake-token'
export OS_TOKEN='fake-token'
export OS_URL=http://localhost:6385
```

読み込みをする
enable OS/IRONIC env

```bash
[vagrant@localhost ~]$ . openrc

[vagrant@localhost ~]$ env | grep -E '(OS|IRONIC)_'
OS_AUTH_TOKEN=fake-token
OS_TOKEN=fake-token
OS_URL=http://localhost:6385
IRONIC_URL=http://localhost:6385
```



```bash
[vagrant@localhost ~]$ ironic node-list
The "ironic" CLI is deprecated and will be removed in the S* release. Please use the "openstack baremetal" CLI instead.
+------+------+---------------+-------------+--------------------+-------------+
| UUID | Name | Instance UUID | Power State | Provisioning State | Maintenance |
+------+------+---------------+-------------+--------------------+-------------+
+------+------+---------------+-------------+--------------------+-------------+

```

openstackコマンドでも、nullだけど、結果が帰ってくる

```bash
[vagrant@localhost ~]$ openstack baremetal node list

[vagrant@localhost ~]$ openstack baremetal node list -f json
[]
```

ipxe から http bootするためのファイルは下記にある

```bash
[vagrant@localhost ~]$ ls -l /httpboot/
total 502028
-rw-r--r--. 1 ironic ironic       404  3月  1 05:57 boot.ipxe
drwxr-xr-x. 3 root   root        4096  3月  1 06:06 deployment_image.d
-rw-r--r--. 1 root   root   276430848  3月  1 06:07 deployment_image.qcow2
drwxr-xr-x. 3 root   root        4096  3月  1 06:02 ipa.d
-rw-r--r--. 1 root   root   232233578  3月  1 06:02 ipa.initramfs
-rw-r--r--. 2 root   root     3174656  3月  1 06:02 ipa.kernel
-rw-r--r--. 2 root   root     3174656  3月  1 06:02 ipa.vmlinuz
-rw-r--r--. 1 root   root      715584  9月  6  2017 ipxe.efi
-rw-r--r--. 1 root   root      276343  9月  6  2017 ipxe.lkrn
drwxr-xr-x. 2 nginx  nginx       4096  3月  1 05:57 ironic-inspector
drwxr-xr-x. 2 ironic ironic      4096  3月  1 05:57 pxelinux.cfg
```

defaultで作られているのは、debian imageのようだ

```bash
[vagrant@localhost ~]$ ls -l /httpboot/deployment_image.d/
total 4
drwxr-xr-x. 2 root root 4096  3月  1 06:06 dib-manifests
[vagrant@localhost ~]$ ls -l /httpboot/deployment_image.d/dib-manifests/
total 40
-rw-r--r--. 1 root root 25357  3月  1 06:06 dib-manifest-dpkg-deployment_image
-rw-r--r--. 1 root root   114  3月  1 06:06 dib-manifest-git-deployment_image
-rw-r--r--. 1 root root    89  3月  1 06:06 dib_arguments
-rw-r--r--. 1 root root   235  3月  1 06:06 dib_environment
[vagrant@localhost ~]$ cat /httpboot/deployment_image.d/dib-manifests/dib_environment
declare -x DIB_ARGS="-o /httpboot/deployment_image.qcow2 -t qcow2 debian vm enable-serial-console simple-init"
declare -x DIB_INSTALLTYPE_simple_init="repo"
declare -x DIB_PYTHON_EXEC="/usr/bin/python2"
declare -x DIB_RELEASE="jessie"
[vagrant@localhost ~]$ cat /httpboot/deployment_image.d/dib-manifests/dib_arguments
-o /httpboot/deployment_image.qcow2 -t qcow2 debian vm enable-serial-console simple-init

```


vm作成のファイルを変数で指定する

```bash
[vagrant@localhost bifrost]$ cat env-vars
export IRONIC_URL=http://localhost:6385/
export OS_AUTH_TOKEN='fake-token'
export BAREMETAL_DATA_FILE=/home/vagrant/bifrost/playbooks/inventory/baremetal.json


[vagrant@localhost bifrost]$ env | grep -E '(OS|IRONIC)_'
OS_AUTH_TOKEN=fake-token
OS_TOKEN=fake-token
OS_URL=http://localhost:6385
IRONIC_URL=http://localhost:6385


[vagrant@localhost bifrost]$ pwd
/home/vagrant/bifrost
[vagrant@localhost bifrost]$ . env-vars


[vagrant@localhost bifrost]$ env | grep -E '(OS|IRONIC|BAREMETAL)_'
OS_AUTH_TOKEN=fake-token
OS_TOKEN=fake-token
BAREMETAL_DATA_FILE=/home/vagrant/bifrost/playbooks/inventory/baremetal.json
OS_URL=http://localhost:6385
IRONIC_URL=http://localhost:6385/
```

そのままだと、自動CIテストコースなので、修正する

```bash
[vagrant@localhost scripts]$ cp -avf test-bifrost.sh ORIG-test-bifrost.sh
‘test-bifrost.sh’ -> ‘ORIG-test-bifrost.sh’
```

    python scripts/split_json.py 3 \
        ${BAREMETAL_DATA_FILE} \
        ${BAREMETAL_DATA_FILE}.new \
        ${BAREMETAL_DATA_FILE}.rest \
        && mv ${BAREMETAL_DATA_FILE}.new ${BAREMETAL_DATA_FILE}



bridgeの設定よりもさきにツールをインストールする

yum install bridge-utils.x86_64 dhcp.x86_64

[root@localhost ~]# ls -l /etc/dhcp/dhcpd.conf
-rw-r--r--. 1 root root 117 May 15  2018 /etc/dhcp/dhcpd.conf



yum install bridge-utils tmux systemd-resolved.x86_64 systemd-resolved.x86_64
yum install dhcping.x86_64 dhcp-libs.x86_64 dhcp-devel.x86_64 dhcp-common.x86_64


[root@localhost network-scripts]# cp -avf ifcfg-eth1 ifcfg-virbr0
cp: overwrite ‘ifcfg-virbr0’? yes
‘ifcfg-eth1’ -> ‘ifcfg-virbr0’


[root@localhost network-scripts]# cp ifcfg-eth1 SPOOL/



cat > /etc/sysconfig/network-scripts/ifcfg-eth1 << __EOF
#VAGRANT-BEGIN
# The contents below are automatically generated by Vagrant. Do not modify.
#VAzxRANT-END
NM_CONTROLLED=no
BOOTPROTO=none
ONBOOT=yes
## IPADDR=192.168.99.10
### NETMASK=255.255.255.0
DEVICE=eth1
NAME=eth1
TYPE="Ethernet"
PEERDNS=no
BRIDGE="virbr0"
__EOF


cat > /etc/sysconfig/network-scripts/ifcfg-virbr0  << __EOF
#VAGRANT-BEGIN
# The contents below are automatically generated by Vagrant. Do not modify.
#VAGRANT-END
NM_CONTROLLED=no
ONBOOT=yes
IPADDR=192.168.99.10
NETMASK=255.255.255.0
GATEWAY=10.0.2.2
DEVICE="virbr0"
NAME="virbr0"
BOOTPROTO=static
PEERDNS=no
TYPE="Bridge"
__EOF


## bifrostでデフオルト有効になっているドライバ

```bash
[root@localhost network-scripts]# cat /etc/ironic/ironic.conf  | grep enabled_
enabled_network_interfaces = noop
enabled_inspect_interfaces = no-inspect,inspector
enabled_boot_interfaces = ilo-virtual-media,pxe
enabled_management_interfaces = ilo,ipmitool,ucsm
enabled_power_interfaces = ilo,ipmitool,ucsm
enabled_deploy_interfaces = iscsi,direct
enabled_hardware_types = ipmi,ilo,cisco-ucs-managed
```






cd scripts/
./test-bifrost-inventory-dhcp.sh

* bifrost-create-vm-nodes まで、実行される

pool errorになる << libvirt の pool

```bash
TASK [bifrost-create-vm-nodes : define a libvirt pool if not set] **************************************************************
task path: /home/vagrant/bifrost/playbooks/roles/bifrost-create-vm-nodes/tasks/prepare_libvirt.yml:121
 [WARNING]: Unable to find 'pool_dir.xml.j2' in expected paths (use -vvvvv to see paths)

File lookup using None as file
fatal: [127.0.0.1]: FAILED! => {
    "msg": "An unhandled exception occurred while running the lookup plugin 'template'. Error was a <class 'ansible.errors.AnsibleError'>, original message: the template file pool_dir.xml.j2 could not be found for the lookup"
}
 [WARNING]: Could not create retry file '/home/vagrant/bifrost/playbooks/test-bifrost-create-vm.retry'.         [Errno 13]
Permission denied: u'/home/vagrant/bifrost/playbooks/test-bifrost-create-vm.retry'


PLAY RECAP *********************************************************************************************************************
127.0.0.1                  : ok=19   changed=10   unreachable=0    failed=1

+ logs_on_exit
+ /home/vagrant/bifrost/scripts/collect-test-info.sh
./test-bifrost-inventory-dhcp.sh: line 143: /home/vagrant/bifrost/scripts/collect-test-info.sh: 入力/出力エラーです
```


## exec script test

sudo ./test-bifrost-inventory-dhcp.sh


BAREMETAL_DATA_FILE=/home/vagrant/bifrost/playbooks/inventory/baremetal.json
>> 中身が更新されている

[vagrant@localhost playbooks]$ pwd
/home/vagrant/bifrost/playbooks

export BIFROST_INVENTORY_SOURCE=/home/vagrant/bifrost/playbooks/inventory/baremetal.json
ansible-playbook -vvvv -i inventory/bifrost_inventory.py enroll-dynamic.yaml


[vagrant@localhost playbooks]$ ironic node-list
The "ironic" CLI is deprecated and will be removed in the S* release. Please use the "openstack baremetal" CLI instead.
+--------------------------------------+---------+---------------+-------------+--------------------+-------------+
| UUID                                 | Name    | Instance UUID | Power State | Provisioning State | Maintenance |
+--------------------------------------+---------+---------------+-------------+--------------------+-------------+
| 878c3113-0035-5033-9f99-46520b89b56d | testvm2 | None          | None        | available          | False       |
| 75d61532-f317-52dc-a232-1274f8389552 | testvm4 | None          | None        | available          | False       |
| 03295955-d852-5115-892e-a31e6cf41b74 | testvm5 | None          | None        | available          | False       |
| 493aacf2-90ec-5e3d-9ce5-ea496f12e2a5 | testvm3 | None          | None        | available          | False       |
| 4e41df61-84b1-5856-bfb6-6b5f2cd3dd11 | testvm1 | None          | None        | available          | False       |
+--------------------------------------+---------+---------------+-------------+--------------------+-------------+

ironicに登録される



export BIFROST_INVENTORY_SOURCE=/home/vagrant/bifrost/playbooks/inventory/baremetal.json
ansible-playbook -vvvv -i inventory/bifrost_inventory.py deploy-dynamic.yaml



[vagrant@localhost playbooks]$ ironic node-list
The "ironic" CLI is deprecated and will be removed in the S* release. Please use the "openstack baremetal" CLI instead.
+--------------------------------------+---------+---------------+-------------+--------------------+-------------+
| UUID                                 | Name    | Instance UUID | Power State | Provisioning State | Maintenance |
+--------------------------------------+---------+---------------+-------------+--------------------+-------------+
| 878c3113-0035-5033-9f99-46520b89b56d | testvm2 | None          | power on    | wait call-back     | False       |
| 75d61532-f317-52dc-a232-1274f8389552 | testvm4 | None          | power on    | wait call-back     | False       |
| 03295955-d852-5115-892e-a31e6cf41b74 | testvm5 | None          | power on    | wait call-back     | False       |
| 493aacf2-90ec-5e3d-9ce5-ea496f12e2a5 | testvm3 | None          | power on    | wait call-back     | False       |
| 4e41df61-84b1-5856-bfb6-6b5f2cd3dd11 | testvm1 | None          | None        | deploying          | False       |
+--------------------------------------+---------+---------------+-------------+--------------------+-------------+


[root@localhost ~]# virsh list --all
 Id    Name                           State
----------------------------------------------------
 1     testvm5                        running
 2     testvm2                        running
 3     testvm3                        running
 4     testvm4                        running
 -     testvm1                        shut off


[vagrant@localhost playbooks]$ vbmc list
+-------------+---------+---------+------+
| Domain name | Status  | Address | Port |
+-------------+---------+---------+------+
| testvm1     | down    | ::      |  623 |
| testvm2     | running | ::      |  624 |
| testvm3     | running | ::      |  625 |
| testvm4     | running | ::      |  626 |
| testvm5     | running | ::      |  627 |
+-------------+---------+---------+------+

[vagrant@localhost playbooks]$ vbmc start testvm1

[vagrant@localhost playbooks]$ vbmc list
+-------------+---------+---------+------+
| Domain name | Status  | Address | Port |
+-------------+---------+---------+------+
| testvm1     | running | ::      |  623 |
| testvm2     | running | ::      |  624 |
| testvm3     | running | ::      |  625 |
| testvm4     | running | ::      |  626 |
| testvm5     | running | ::      |  627 |
+-------------+---------+---------+------+

[vagrant@localhost playbooks]$ sudo virsh start testvm1
ドメイン testvm1 が起動されました

[vagrant@localhost playbooks]$ sudo virsh list --all
 Id    名前                         状態
----------------------------------------------------
 1     testvm5                        実行中
 2     testvm2                        実行中
 3     testvm3                        実行中
 4     testvm4                        実行中
 5     testvm1                        実行中


## GUI install

sudo yum -y groupinstall "Server with GUI"


sudo yum -y install xterm.x86_64


sudo yum install -y virt-manager.noarch
sudo yum -y groupinstall "X Window System"


## vbmc

[vagrant@localhost bifrost]$ vbmc list
+-------------+---------+---------+------+
| Domain name | Status  | Address | Port |
+-------------+---------+---------+------+
| testvm1     | running | ::      |  623 |
| testvm2     | running | ::      |  624 |
| testvm3     | running | ::      |  625 |
| testvm4     | running | ::      |  626 |
| testvm5     | running | ::      |  627 |
+-------------+---------+---------+------+



[vagrant@localhost ~]$ openstack baremetal driver list
+---------------------+-----------------------+
| Supported driver(s) | Active host(s)        |
+---------------------+-----------------------+
| cisco-ucs-managed   | localhost.localdomain |
| ilo                 | localhost.localdomain |
| ipmi                | localhost.localdomain |
+---------------------+-----------------------+

[vagrant@localhost ~]$ sudo nvim /etc/ironic/ironic.conf
  > deploy driver << ansible追加>>

[vagrant@localhost ~]$ sudo systemctl list-unit-files | grep ironic
ironic-api.service                            enabled
ironic-conductor.service                      enabled
ironic-inspector.service                      enabled



export BIFROST_INVENTORY_SOURCE=/home/vagrant/bifrost/playbooks/inventory/baremetal.json
ansible-playbook -vvvv -i inventory/bifrost_inventory.py deploy-dynamic.yaml


## test env. setup

sudo yum install libvirt-python lxml libvirt.x86_64 virt-manager.noarch

sudo yum install libguestfs-bash-completion.noarch ¥
  libguestfs-xfs.x86_64 libguestfs-rsync.x86_64 ¥
  libguestfs.x86_64 libguestfs-rescue.x86_64 libguestfs-tools.noarch libguestfs-tools-c.x86_64



## nfs vagrant sync_folder problems

nfs sync folder から、sshfs sync folder に変更する

Another workaround is to use sshfs plugin for vagrant
https://github.com/dustymabe/vagrant-sshfs
Slower than NFS but it works

```bash
$ vagrant plugin install vagrant-sshfs
change the Vagrantfile
config.vm.synced_folder "/Users/someuser/shared", "/home/vagrant/shared", type: "sshfs"
$ vagrant reload
```


```bash
YINN0872:vagrant_dev_env usr0101039$ vagrant plugin install vagrant-sshfs
Installing the 'vagrant-sshfs' plugin. This can take a few minutes...
Fetching: win32-process-0.8.3.gem (100%)
Fetching: vagrant-sshfs-1.3.1.gem (100%)
Installed the plugin 'vagrant-sshfs (1.3.1)'!
```


sudo yum localinstall python2-openstackdocstheme-1.18.1-1.el7.noarch.rpm

sudo yum localinstall /home/vagrant/rpmbuild/RPMS/noarch/python2-virtualbmc-tests-1.4.0-1.el7.noarch.rpm /home/vagrant/rpmbuild/RPMS/noarch/python2-virtualbmc-1.4.0-1.el7.noarch.rpm



sudo yum install czmq.x86_64 python-zmq.x86_64

[vagrant@localhost SPECS]$ sudo yum install zeromq openpgm python-zmq.x86_64



[vagrant@localhost SPECS]$ vbmc help
usage: vbmc [--version] [-v | -q] [--log-file LOG_FILE] [-h] [--debug]
            [--no-daemon]

Virtual Baseboard Management Controller (BMC) backed by virtual machines

optional arguments:
  --version            show program's version number and exit
  -v, --verbose        Increase verbosity of output. Can be repeated.
  -q, --quiet          Suppress output except warnings and errors.
  --log-file LOG_FILE  Specify a file to log output. Disabled by default.
  -h, --help           Show help message and exit.
  --debug              Show tracebacks on errors.
  --no-daemon          Do not start vbmcd automatically

Commands:
  add            Create a new BMC for a virtual machine instance
  complete       print bash completion command (cliff)
  delete         Delete a virtual BMC for a virtual machine instance
  help           print detailed help for another command (cliff)
  list           List all virtual BMC instances
  show           Show virtual BMC properties
  start          Start a virtual BMC for a virtual machine instance
  stop           Stop a virtual BMC for a virtual machine instance


[vagrant@localhost SPECS]$ vbmc help add
usage: vbmc add [-h] [--username USERNAME] [--password PASSWORD] [--port PORT]
                [--address ADDRESS] [--libvirt-uri LIBVIRT_URI]
                [--libvirt-sasl-username LIBVIRT_SASL_USERNAME]
                [--libvirt-sasl-password LIBVIRT_SASL_PASSWORD]
                domain_name

Create a new BMC for a virtual machine instance

positional arguments:
  domain_name           The name of the virtual machine

optional arguments:
  -h, --help            show this help message and exit
  --username USERNAME   The BMC username; defaults to "admin"
  --password PASSWORD   The BMC password; defaults to "password"
  --port PORT           Port to listen on; defaults to 623
  --address ADDRESS     The address to bind to (IPv4 and IPv6 are supported);
                        defaults to ::
  --libvirt-uri LIBVIRT_URI
                        The libvirt URI; defaults to "qemu:///system"
  --libvirt-sasl-username LIBVIRT_SASL_USERNAME
                        The libvirt SASL username; defaults to None
  --libvirt-sasl-password LIBVIRT_SASL_PASSWORD
                        The libvirt SASL password; defaults to None


[vagrant@localhost SPECS]$ sudo vbmc add --username ADMIN --password ADMIN --port 623 testvm1

[vagrant@localhost SPECS]$ sudo vbmc add --username ADMIN --password ADMIN --port 624 testvm2


[vagrant@localhost SPECS]$ sudo vbmc list
+-------------+--------+---------+------+
| Domain name | Status | Address | Port |
+-------------+--------+---------+------+
| testvm1     | down   | ::      |  623 |
| testvm2     | down   | ::      |  624 |
+-------------+--------+---------+------+


[vagrant@localhost ~]$ . ./openrc


[vagrant@localhost ~]$ ironic node-list
WARNING: yacc table file version is out of date
The "ironic" CLI is deprecated and will be removed in the S* release. Please use the "openstack baremetal" CLI instead.
Unable to establish connection to http://localhost:6385/v1/nodes: HTTPConnectionPool(host='localhost', port=6385): Max retries exceeded with url: /v1/nodes (Caused by NewConnectionError('<requests.packages.urllib3.connection.HTTPConnection object at 0x7f0569a85110>: Failed to establish a new connection: [Errno 111] Connection refused',))


[vagrant@localhost ~]$ sudo systemctl list-unit-files | grep ironic
ironic-api.service                            enabled
ironic-conductor.service                      enabled
ironic-inspector.service                      enabled


[vagrant@localhost ~]$ ps -aef | grep ironic
vagrant   9017  5565  0 08:24 pts/0    00:00:00 grep --color=auto ironic


[vagrant@localhost ~]$ ps -aef | grep sql
mysql      936     1  0 07:15 ?        00:00:00 /bin/sh /usr/bin/mysqld_safe --basedir=/usr
mysql     1301   936  0 07:15 ?        00:00:03 /usr/libexec/mysqld --basedir=/usr --datadir=/var/lib/mysql --plugin-dir=/usr/lib64/mysql/plugin --log-error=/var/log/mariadb/mariadb.log --pid-file=/var/run/mariadb/mariadb.pid --socket=/var/lib/mysql/mysql.sock
vagrant   9021  5565  0 08:24 pts/0    00:00:00 grep --color=auto sql


[vagrant@localhost ~]$ systemctl start ironic-api.service
==== AUTHENTICATING FOR org.freedesktop.systemd1.manage-units ===
Authentication is required to manage system services or units.
Authenticating as: root
Password:


[vagrant@localhost ~]$ sudo systemctl start ironic-api.service
[vagrant@localhost ~]$ sudo systemctl start ironic-inspector.service
[vagrant@localhost ~]$ sudo systemctl start ironic-conductor.service


[vagrant@localhost ~]$ ps -aef | grep ironic
ironic    9045     1  6 08:24 ?        00:00:02 /usr/bin/python2 /bin/ironic-api --config-file /etc/ironic/ironic.conf
ironic    9056  9045  0 08:24 ?        00:00:00 /usr/bin/python2 /bin/ironic-api --config-file /etc/ironic/ironic.conf
ironic    9057  9045  0 08:24 ?        00:00:00 /usr/bin/python2 /bin/ironic-api --config-file /etc/ironic/ironic.conf
ironic    9058  9045  0 08:24 ?        00:00:00 /usr/bin/python2 /bin/ironic-api --config-file /etc/ironic/ironic.conf
ironic    9059  9045  0 08:24 ?        00:00:00 /usr/bin/python2 /bin/ironic-api --config-file /etc/ironic/ironic.conf
ironic    9069     1 11 08:25 ?        00:00:02 /usr/bin/python2 /bin/ironic-inspector --config-file /etc/ironic-inspector/inspector.conf
ironic    9092     1 34 08:25 ?        00:00:03 /usr/bin/python2 /bin/ironic-conductor --config-file /etc/ironic/ironic.conf
vagrant   9112  5565  0 08:25 pts/0    00:00:00 grep --color=auto ironic
[vagrant@localhost ~]$


[vagrant@localhost ~]$ sudo yum install dhcp



[vagrant@localhost ~]$ getenforce
Enforcing
[vagrant@localhost ~]$ sudo su -
Last login: 水  3月  6 01:48:55 UTC 2019 on pts/0
[root@localhost ~]# setenforce 0
[root@localhost ~]# getenforce
Permissive
[root@localhost ~]# cat /etc/sysconfig/selinux

# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=enforcing
# SELINUXTYPE= can take one of three two values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected.
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted



[root@localhost ~]# grep SELINUX /etc/sysconfig/selinux
# SELINUX= can take one of these three values:
########### SELINUX=enforcing
SELINUX=disabled
# SELINUXTYPE= can take one of three two values:
SELINUXTYPE=targeted



[vagrant@localhost bifrost]$ ls -l /etc/yum.repos.d/
total 56
-rw-r--r--. 1 root root 1664  8月 13  2018 CentOS-Base.repo
-rw-r--r--. 1 root root 1309  8月 13  2018 CentOS-CR.repo
-rw-r--r--. 1 root root  850  7月 31  2018 CentOS-Ceph-Luminous.repo
-rw-r--r--. 1 root root  649  8月 13  2018 CentOS-Debuginfo.repo
-rw-r--r--. 1 root root  630  8月 13  2018 CentOS-Media.repo
-rw-r--r--. 1 root root 1201  8月 13  2018 CentOS-OpenStack-queens.repo
-rw-r--r--. 1 root root  612  2月  1 07:40 CentOS-QEMU-EV.repo
-rw-r--r--. 1 root root 1331  8月 13  2018 CentOS-Sources.repo
-rw-r--r--. 1 root root  353  7月 31  2018 CentOS-Storage-common.repo
-rw-r--r--. 1 root root 4768  8月 13  2018 CentOS-Vault.repo
-rw-r--r--. 1 root root  314  8月 13  2018 CentOS-fasttrack.repo
-rw-r--r--. 1 root root 1050 10月  2  2017 epel-testing.repo
-rw-r--r--. 1 root root  951 10月  2  2017 epel.repo



[vagrant@localhost bifrost]$ ls /usr/lib/python2.7/site-packages/ironic
__init__.py  __init__.pyc  api  cmd  common  conductor  conf  db  dhcp  drivers  hacking  objects  tests  version.py  version.pyc
[vagrant@localhost bifrost]$ ls /usr/lib/python2.7/site-packages/ironic/drivers/
__init__.py   cisco_ucs.py   fake_hardware.py   hardware_type.py   ipmi.py   modules                  snmp.py    xclarity.py
__init__.pyc  cisco_ucs.pyc  fake_hardware.pyc  hardware_type.pyc  ipmi.pyc  raid_config_schema.json  snmp.pyc   xclarity.pyc
base.py       drac.py        generic.py         ilo.py             irmc.py   redfish.py               utils.py
base.pyc      drac.pyc       generic.pyc        ilo.pyc            irmc.pyc  redfish.pyc              utils.pyc
[vagrant@localhost bifrost]$ ls /usr/lib/python2.7/site-packages/ironic/drivers/modules/
__init__.py            boot.ipxe                      fake.py            ipmitool.pyc          noop.pyc                  snmp.py
__init__.pyc           boot_mode_utils.py             fake.pyc           ipxe.py               noop_mgmt.py              snmp.pyc
agent.py               boot_mode_utils.pyc            ilo                ipxe.pyc              noop_mgmt.pyc             storage
agent.pyc              cimc                           image_cache.py     ipxe_config.template  pxe.py                    ucs
agent_base_vendor.py   console_utils.py               image_cache.pyc    irmc                  pxe.pyc                   xclarity
agent_base_vendor.pyc  console_utils.pyc              inspect_utils.py   iscsi_deploy.py       pxe_base.py
agent_client.py        deploy_utils.py                inspect_utils.pyc  iscsi_deploy.pyc      pxe_base.pyc
agent_client.pyc       deploy_utils.pyc               inspector.py       master_grub_cfg.txt   pxe_config.template
agent_config.template  drac                           inspector.pyc      network               pxe_grub_config.template
ansible                elilo_efi_pxe_config.template  ipmitool.py        noop.py               redfish


vbmc << start しないと listenしない>>




sudo yum -y install OpenIPMI-libs.x86_64 OpenIPMI.x86_64


## 2nd test

export BIFROST_INVENTORY_SOURCE=/home/vagrant/bifrost/playbooks/inventory/baremetal.json; ansible-playbook -vvvv -i inventory/bifrost_inventory.py enroll-dynamic.yaml


## ipa image : fedora image generate

export DIB_DEV_USER_USERNAME=devuser
export DIB_DEV_USER_PWDLESS_SUDO=yes
export DIB_DEV_USER_PASSWORD=dr86Fatc
disk-image-create -o /httpboot/ipa.image-custom-fedora fedora ironic-agent devuser enable-serial-console dynamic-login

>> kernelが起動中に固まる << call trace >>

## ipa image : fedora image generate

export DIB_DEV_USER_USERNAME=devuser
export DIB_DEV_USER_PWDLESS_SUDO=yes
export DIB_DEV_USER_PASSWORD=dr86Fatc
disk-image-create -o /httpboot/ipa.image-custom-f29mini fedora-minimal ironic-agent devuser enable-serial-console dynamic-login


* root

export DIB_DEV_USER_USERNAME=devuser
export DIB_DEV_USER_PWDLESS_SUDO=yes
export DIB_DEV_USER_PASSWORD=dr86Fatc
disk-image-create -o /httpboot/ipa.image-custom-centos7 centos7 ironic-agent devuser enable-serial-console dynamic-login


## 3rd test
unset OS_AUTH_TOKEN
unset OS_TOKEN
export BIFROST_INVENTORY_SOURCE=/home/vagrant/bifrost/playbooks/inventory/baremetal.yml; ansible-playbook -vvvv -i inventory/bifrost_inventory.py enroll-dynamic.yaml


export BIFROST_INVENTORY_SOURCE=/home/vagrant/bifrost/playbooks/inventory/baremetal.yml; inventory/bifrost_inventory.py

export BIFROST_INVENTORY_SOURCE=/home/vagrant/bifrost/playbooks/inventory/baremetal.yml; ansible-playbook -vvvv -i inventory/bifrost_inventory.py deploy-dynamic.yaml



落ちているのは、下記のkernel
Ubuntu 4.4.0-142.168-generic 4.4.167

sudo yum install ipxe-bootimgs.noarch ipxe-roms.noarch ipxe-roms-qemu.noarch


[vagrant@localhost httpboot]$ rpm -qli ipxe-bootimgs-20170123-1.git4e85b27.el7_4.1.noarch
Name        : ipxe-bootimgs
Version     : 20170123
Release     : 1.git4e85b27.el7_4.1
Architecture: noarch
Install Date: 2019年03月05日 06時40分50秒
Group       : Development/Tools
Size        : 3748830
License     : GPLv2 and BSD
Signature   : RSA/SHA256, 2017年09月07日 12時31分23秒, Key ID 24c6a8a7f4a80eb5
Source RPM  : ipxe-20170123-1.git4e85b27.el7_4.1.src.rpm
Build Date  : 2017年09月06日 17時49分24秒
Build Host  : c1bm.rdu2.centos.org
Relocations : (not relocatable)
Packager    : CentOS BuildSystem <http://bugs.centos.org>
Vendor      : CentOS
URL         : http://ipxe.org/
Summary     : Network boot loader images in bootable USB, CD, floppy and GRUB formats
Description :
iPXE is an open source network bootloader. It provides a direct
replacement for proprietary PXE ROMs, with many extra features such as
DNS, HTTP, iSCSI, etc.

This package contains the iPXE boot images in USB, CD, floppy, and PXE
UNDI formats.
/usr/share/doc/ipxe-bootimgs-20170123
/usr/share/doc/ipxe-bootimgs-20170123/COPYING
/usr/share/doc/ipxe-bootimgs-20170123/COPYING.GPLv2
/usr/share/doc/ipxe-bootimgs-20170123/USAGE
/usr/share/ipxe
/usr/share/ipxe/ipxe.dsk
/usr/share/ipxe/ipxe.efi
/usr/share/ipxe/ipxe.iso
/usr/share/ipxe/ipxe.lkrn
/usr/share/ipxe/ipxe.usb
/usr/share/ipxe/undionly.kpxe
[vagrant@localhost httpboot]$ file /usr/share/ipxe/ipxe.lkrn
/usr/share/ipxe/ipxe.lkrn: Linux kernel x86 boot executable bzImage, version 1.0.0+ (4e85b27), RO-rootFS,
[vagrant@localhost httpboot]$ file /tftpboot/ipxe.lkrn
/tftpboot/ipxe.lkrn: Linux kernel x86 boot executable bzImage, version 1.0.0+ (4e85b27), RO-rootFS,


https://rpmfind.net/linux/RPM/fedora/devel/rawhide/armhfp/i/ipxe-bootimgs-20190125-1.git36a4c85f.fc30.noarch.html

これをbuildしてみる


[vagrant@localhost ~]$ rpm2cpio ipxe-bootimgs-20190125-1.git36a4c85f.el7.noarch.rpm | cpio -idv
./usr/share/doc/ipxe-bootimgs-20190125
./usr/share/doc/ipxe-bootimgs-20190125/COPYING
./usr/share/doc/ipxe-bootimgs-20190125/COPYING.GPLv2
./usr/share/doc/ipxe-bootimgs-20190125/COPYING.UBDL
./usr/share/ipxe
./usr/share/ipxe/ipxe-i386.efi
./usr/share/ipxe/ipxe-x86_64.efi
./usr/share/ipxe/ipxe.dsk
./usr/share/ipxe/ipxe.iso
./usr/share/ipxe/ipxe.lkrn
./usr/share/ipxe/ipxe.usb
./usr/share/ipxe/undionly.kpxe
8731 blocks
[vagrant@localhost ~]$ file ./usr/share/ipxe/ipxe.lkrn
./usr/share/ipxe/ipxe.lkrn: Linux kernel x86 boot executable bzImage, version 1.0.0+, RO-rootFS,
[vagrant@localhost ~]$ cp ./usr/share/ipxe/ipxe.lkrn /tftpboot/
ipxe.efi       ipxe.lkrn      map-file       pxelinux.cfg/  undionly.kpxe
[vagrant@localhost ~]$ sudo cp  ./usr/share/ipxe/ipxe.lkrn /tftpboot/
[vagrant@localhost ~]$ sudo cp ./usr/share/ipxe/undionly.kpxe /tftpboot/


## 4th ramdisk

export DIB_DEV_USER_USERNAME=devuser
export DIB_DEV_USER_PWDLESS_SUDO=yes
export DIB_DEV_USER_PASSWORD=dr86Fatc
disk-image-create -o /httpboot/ipa.image-custom-fedora fedora-minimal ironic-agent ramdisk devuser enable-serial-console



[vagrant@localhost playbooks]$ openstack baremetal node list
WARNING: yacc table file version is out of date
Missing value auth-url required for auth plugin password
[vagrant@localhost playbooks]$ . ../openrc
[vagrant@localhost playbooks]$ openstack baremetal node list
WARNING: yacc table file version is out of date
+--------------------------------------+---------+---------------+-------------+--------------------+-------------+
| UUID                                 | Name    | Instance UUID | Power State | Provisioning State | Maintenance |
+--------------------------------------+---------+---------------+-------------+--------------------+-------------+
| 4e41df61-84b1-5856-bfb6-6b5f2cd3dd11 | testvm1 | None          | None        | deploy failed      | False       |
+--------------------------------------+---------+---------------+-------------+--------------------+-------------+
[vagrant@localhost playbooks]$ openstack baremetal node deploy testvm1
WARNING: yacc table file version is out of date
[vagrant@localhost playbooks]$ openstack baremetal node list
WARNING: yacc table file version is out of date
+--------------------------------------+---------+---------------+-------------+--------------------+-------------+
| UUID                                 | Name    | Instance UUID | Power State | Provisioning State | Maintenance |
+--------------------------------------+---------+---------------+-------------+--------------------+-------------+
| 4e41df61-84b1-5856-bfb6-6b5f2cd3dd11 | testvm1 | None          | None        | deploying          | False       |
+--------------------------------------+---------+---------------+-------------+--------------------+-------------+
[vagrant@localhost playbooks]$ ls -l /httpboot/pxelinux.cfg/
total 4
lrwxrwxrwx. 1 ironic ironic  46  3月  7 07:31 52-54-00-d2-ae-66 -> ../4e41df61-84b1-5856-bfb6-6b5f2cd3dd11/config
-rw-r--r--. 1 ironic ironic 381  3月  5 06:44 default
[vagrant@localhost playbooks]$




































































; ansible-playbook -vvvv -i inventory/bifrost_inventory.py enroll-dynamic.yaml