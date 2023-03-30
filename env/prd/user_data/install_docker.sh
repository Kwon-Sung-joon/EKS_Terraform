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
  - name : admin
    groups : [ wheel ]
    shell : /bin/bash
    lock_passwd : false
    plain_text_passwd: 'admin!1'
  - name : root
    groups : [ wheel ]
    shell : /bin/bash
    lock_passwd : false
    plain_text_passwd: 'admin!1'

--//
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="userdata.txt"
#!/bin/bash


sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
systemctl restart sshd

yum update -y
amazon-linux-extras install docker -y
systemctl enable docker
systemctl start docker
sudo curl -o kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.23.7/2022-06-29/bin/linux/amd64/kubectl
sudo chmod +x /usr/local/bin/kubectl
echo "alias k='kubectl'" >> ~/.bash_profile
source ~/.bash_profile

sudo yum install -y jq
sudo yum install -y bash-completion



