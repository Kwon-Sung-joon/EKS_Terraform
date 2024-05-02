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
    plain_text_passwd: 'admin01'

--//
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="userdata.txt"

#!/bin/bash
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd


curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.26.12/2024-01-04/bin/linux/arm64/kubectl
chmod +x /usr/local/bin/kubectl
echo "alias k='kubectl'" >> ~/.bash_profile
source ~/.bash_profile
dnf install -y jq
dnf install -y bash-completion
aws eks update-kubeconfig --region ap-northeast-2 --name ${CLUSTER-NAME}