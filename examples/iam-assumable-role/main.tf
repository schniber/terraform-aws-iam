provider "aws" {
  region = "eu-west-1"
}

###############################
# IAM assumable role for admin
###############################
module "iam_assumable_role_admin" {
  source = "../../modules/iam-assumable-role"

  # https://aws.amazon.com/blogs/security/announcing-an-update-to-iam-role-trust-policy-behavior/
  allow_self_assume_role = true

  trusted_role_arns = [
    "arn:aws:iam::307990089504:root",
    "arn:aws:iam::835367859851:user/anton",
  ]

  trusted_role_services = [
    "codedeploy.amazonaws.com"
  ]

  create_role             = true
  create_instance_profile = true

  role_name         = "admin"
  role_requires_mfa = true

  attach_admin_policy = true

  tags = {
    Role = "Admin"
  }
}

##########################################
# IAM assumable role with custom policies
##########################################
module "iam_assumable_role_custom" {
  source = "../../modules/iam-assumable-role"

  trusted_role_arns = [
    "arn:aws:iam::307990089504:root",
  ]

  trusted_role_services = [
    "codedeploy.amazonaws.com"
  ]

  create_role = true

  role_name_prefix  = "custom-"
  role_requires_mfa = false

  role_sts_externalid = "some-id-goes-here"

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonCognitoReadOnly",
    "arn:aws:iam::aws:policy/AlexaForBusinessFullAccess",
    module.iam_policy.arn
  ]
  #  number_of_custom_role_policy_arns = 3
}

####################################################
# IAM assumable role with multiple sts external ids
####################################################
module "iam_assumable_role_sts" {
  source = "../../modules/iam-assumable-role"

  trusted_role_arns = [
    "arn:aws:iam::307990089504:root",
  ]

  trusted_role_services = [
    "codedeploy.amazonaws.com"
  ]

  create_role = true

  role_name         = "custom_sts"
  role_requires_mfa = true

  role_sts_externalid = [
    "some-id-goes-here",
    "another-id-goes-here",
  ]

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonCognitoReadOnly",
    "arn:aws:iam::aws:policy/AlexaForBusinessFullAccess",
    module.iam_policy.arn
  ]
  #  number_of_custom_role_policy_arns = 3
}

#########################################
# IAM assumable role with custom trust policy
#########################################
module "iam_assumable_role_custom_trust_policy" {
  source = "../../modules/iam-assumable-role"

  create_role = true

  role_name = "iam_assumable_role_custom_trust_policy"

  custom_role_trust_policy = data.aws_iam_policy_document.custom_trust_policy.json
  custom_role_policy_arns  = ["arn:aws:iam::aws:policy/AmazonCognitoReadOnly"]
}

data "aws_iam_policy_document" "custom_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = ["some-ext-id"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = ["o-someorgid"]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

#########################################
# IAM policy
#########################################
module "iam_policy" {
  source = "../../modules/iam-policy"

  name        = "example"
  path        = "/"
  description = "My example policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# #########################################
# # IAM assumable role with custom trust policy 2
# #########################################

resource "aws_iam_saml_provider" "idp_saml" {
  name                   = "idp_saml"
  saml_metadata_document = file("saml-metadata.xml")
}

data "aws_iam_policy_document" "custom_trust_policy_2" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithSAML"]

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_saml_provider.idp_saml.id
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "SAML:aud"
      values = [
        "https://signin.aws.amazon.com/saml"
      ]
    }
  }
  statement {
    effect  = "Allow"
    actions = ["sts:TagSession"]

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_saml_provider.idp_saml.id
      ]
    }
    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/groups"
      values   = ["*"]
    }
  }
}

module "iam_assumable_role_custom_trust_policy_2" {
  source = "../../modules/iam-assumable-role"

  create_role = true

  role_name = "iam_assumable_role_custom_trust_policy_2"

  create_custom_role_trust_policy = true
  custom_role_trust_policy        = data.aws_iam_policy_document.custom_trust_policy_2.json
  custom_role_policy_arns         = ["arn:aws:iam::aws:policy/AmazonCognitoReadOnly"]
}
