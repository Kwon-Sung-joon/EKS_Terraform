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

dnf install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.26.12/2024-01-04/bin/linux/amd64/kubectl
chmod +x ./kubectl

HOME=/home/ec2-user
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin
echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null

dnf install -y jq
dnf install -y bash-completion
su ec2-user -c "aws eks update-kubeconfig --region ap-northeast-2 --name ${CLUSTER-NAME}"
curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 /tmp/get_helm.sh
sh +x /tmp/get_helm.sh
rm -f /tmp/get_helm.sh

curl -sL https://github.com/derailed/k9s/releases/download/v0.25.18/k9s_Linux_x86_64.tar.gz | sudo tar \
 xfz - -C /usr/local/bin k9s