resource "aws_instance" "tf-bastion" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  key_name               = var.keypair_name
  iam_instance_profile   = aws_iam_instance_profile.bastion_profile.name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  subnet_id              = var.subnet_id1
  user_data              = file(var.user_data)
  tags = {
    Name = "${var.alltag}-ec2"
  }
}
resource "aws_security_group" "bastion_sg" {
  name   = "bastion_sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "bastion_profile"
  role = aws_iam_role.bastion_role.name
}

resource "aws_iam_role" "bastion_role" {
  name               = "bastion_role"
  path               = "/"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service":  "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
}
EOF
}

resource "aws_iam_policy" "bastion_policy" {
  name        = "bastion-policy"
  path        = "/"
  description = "Bastion host policy"
  policy      = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
	  {
	    "Action":  ["ec2:*","ecr:*"],
	    "Effect": "Allow",
	    "Resource": "*"
	  }
	]
}
EOF
}

resource "aws_iam_policy_attachment" "attach-bastion-pocliy" {
  name       = "bastion-attach"
  roles      = [aws_iam_role.bastion_role.name]
  policy_arn = aws_iam_policy.bastion_policy.arn
}

