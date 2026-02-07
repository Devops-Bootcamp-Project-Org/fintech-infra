# IAM Roles
import { to = module.eks-client-node.aws_iam_role.eks_client_ssm_role; id = "eks-client-ssm-role" }
import { to = module.github-self-hosted-runner.aws_iam_role.github_runner_ssm_role; id = "github-runner-ssm-role" }
import { to = module.iam.aws_iam_role.github_actions_role; id = "prod-GitHubActionsECR" }

# IAM Policies
import { to = module.iam.aws_iam_policy.github_ecr_policy; id = "arn:aws:iam::805703880776:policy/prod-GitHubECRPolicy" }
import { to = module.iam.aws_iam_policy.github_eks_policy; id = "arn:aws:iam::805703880776:policy/prod-GitHubEKSPolicy" }

# KMS and CloudWatch
import { to = module.eks.module.eks.module.kms.aws_kms_alias.this["cluster"]; id = "alias/eks/prod-fintek-cluster" }
import { to = module.eks.module.eks.aws_cloudwatch_log_group.this[0]; id = "/aws/eks/prod-fintek-cluster/cluster" }