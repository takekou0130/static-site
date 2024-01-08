// see https://zenn.dev/kou_pg_0131/articles/gh-actions-oidc-aws
// OIDC provider
data "http" "github_actions_openid_configuration" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

data "tls_certificate" "github_actions" {
  url = jsondecode(data.http.github_actions_openid_configuration.response_body).jwks_uri
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = data.tls_certificate.github_actions.certificates[*].sha1_fingerprint
}

// IAM Role for terraform lint and plan (using in any feature branches)
data "aws_iam_policy_document" "assume_role_for_any_branches" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      // allow any branches
      values = ["repo:takekou0130/static-site:*"]
    }
  }
}

resource "aws_iam_role" "oidc_readonly" {
  name               = "oidc-readonly-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_for_any_branches.json
}

resource "aws_iam_role_policy_attachment" "readonly_for_terraform" {
  role       = aws_iam_role.oidc_readonly.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "write_to_tf_lock" {
  role       = aws_iam_role.oidc_readonly.name
  policy_arn = aws_iam_policy.write_to_tf_lock.arn
}

resource "aws_iam_policy" "write_to_tf_lock" {
  name   = "allow-write-to-tf-lock"
  policy = data.aws_iam_policy_document.write_to_tf_lock.json
}

data "aws_iam_policy_document" "write_to_tf_lock" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [aws_dynamodb_table.tfstate.arn]
  }
}
