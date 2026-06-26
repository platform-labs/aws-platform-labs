# Two distinct roles, on purpose - this is the gap identified when reviewing
# Lab 2's Terraform (it only had a Task Execution Role, no Task Role):
#
#   Task Execution Role -> ECS infrastructure concern
#                           (pull image from ECR, write logs to CloudWatch)
#
#   Task Role           -> application's own AWS permissions
#                           (the running container calling S3, etc.)
#
# This is a very common interview question: "what's the difference between
# ECS Task Execution Role and Task Role?"

data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# --- Task Execution Role: ECS infrastructure, not the app ---

resource "aws_iam_role" "task_execution" {
  name               = "${var.project_name}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
}

resource "aws_iam_role_policy_attachment" "task_execution_managed" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- Task Role: the application's own permissions ---
#
# Lab 1/Lab 2 used AmazonS3FullAccess (managed policy) on the EC2 instance
# role - noted there as "fine for a lab, too broad for production". Here we
# scope it down to just the one bucket and just the actions the app needs,
# since this is the first lab where Task Role is being done deliberately
# rather than inherited from an earlier shortcut.

resource "aws_iam_role" "task_role" {
  name               = "${var.project_name}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
}

data "aws_iam_policy_document" "task_role_s3" {
  statement {
    sid    = "WalletApiS3Access"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
    ]
    resources = [
      "arn:aws:s3:::${var.s3_bucket}/*",
    ]
  }
}

resource "aws_iam_role_policy" "task_role_s3" {
  name   = "${var.project_name}-task-role-s3-access"
  role   = aws_iam_role.task_role.id
  policy = data.aws_iam_policy_document.task_role_s3.json
}
