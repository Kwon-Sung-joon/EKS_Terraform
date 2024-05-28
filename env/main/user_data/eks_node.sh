Content-Type: multipart/mixed; boundary="//"
MIME-Version: 1.0
--//
Content-Type: text/cloud-config; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="cloud-config.txt"
#cloud-config
cloud_final_modules:
- [scripts-user, always]
- [users-groups, always]

users:
  - name : ec2-user
    groups : [ wheel ]
    shell : /bin/bash
    lock_passwd : false
    plain_text_passwd: 'admin0!'

--//
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="userdata.txt"

#!/bin/bash
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd

set -ex
/etc/eks/bootstrap.sh ${CLUSTER-NAME} \
  --b64-cluster-ca  ${B64-CLUSTER-CA}\
  --apiserver-endpoint  ${APISERVER-ENDPOINT}\
  --dns-cluster-ip  ${DNS-CLUSTER-IP}\
  --container-runtime containerd

systemctl restart kubelet