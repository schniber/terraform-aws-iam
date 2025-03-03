provider "aws" {
  region = "eu-west-1"
}

###############################
# IAM assumable role for admin
###############################
module "iam_assumable_role_admin" {
  source = "../../modules/iam-assumable-role-with-oidc"

  create_role = true

  role_name = "role-with-oidc"

  tags = {
    Role = "role-with-oidc"
  }

  provider_url  = "oidc.eks.eu-west-1.amazonaws.com/id/BA9E170D464AF7B92084EF72A69B9DC8"
  provider_urls = ["oidc.eks.eu-west-1.amazonaws.com/id/AA9E170D464AF7B92084EF72A69B9DC8"]

  role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
  ]

  oidc_fully_qualified_subjects = ["system:serviceaccount:default:sa1", "system:serviceaccount:default:sa2"]
}

#####################################
# IAM assumable role with self assume
#####################################
module "iam_assumable_role_self_assume" {
  source = "../../modules/iam-assumable-role-with-oidc"

  create_role            = true
  allow_self_assume_role = true

  role_name = "role-with-oidc-self-assume"

  tags = {
    Role = "role-with-oidc-self-assume"
  }

  provider_url  = "oidc.eks.eu-west-1.amazonaws.com/id/BA9E170D464AF7B92084EF72A69B9DC8"
  provider_urls = ["oidc.eks.eu-west-1.amazonaws.com/id/AA9E170D464AF7B92084EF72A69B9DC8"]

  role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
  ]

  oidc_fully_qualified_subjects = ["system:serviceaccount:default:sa1", "system:serviceaccount:default:sa2"]
}

#####################################
# IAM assumable role with custom trust policy
#####################################
module "iam_assumable_role_custom_trust" {
  source = "../../modules/iam-assumable-role-with-oidc"

  create_role                     = true
  create_custom_role_trust_policy = true
  custom_role_trust_policy        = data.aws_iam_policy_document.custom_trust_policy.json

  role_name = "role-with-oidc-custom-trust"

  tags = {
    Role = "role-with-oidc-custom-trust"
  }

  provider_url  = "oidc.eks.eu-west-1.amazonaws.com/id/BA9E170D464AF7B92084EF72A69B9DC8"
  provider_urls = ["oidc.eks.eu-west-1.amazonaws.com/id/AA9E170D464AF7B92084EF72A69B9DC8"]

  role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
  ]

  oidc_fully_qualified_subjects = ["system:serviceaccount:default:sa1", "system:serviceaccount:default:sa2"]
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
