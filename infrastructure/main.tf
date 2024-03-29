# Data

data "aws_iam_policy_document" "lambda_role_template" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "lambda_policy_template" {
  statement {
    actions   = [
      "logs:CreateLogGroup",
    ]
    resources = [
      "arn:aws:logs:*:*",
    ]
  }

  statement {
    actions   = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:*:*:*:*:*",
    ]
  }

  statement {
    actions   = [
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeInstances",
      "ec2:AttachNetworkInterface",
    ]
    resources = [
      "*",
    ]
  }

}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../src/lambda_function.py"
  output_path = "tmp/lambda.zip"
}

# IAM

resource "aws_iam_role" "lambda_role" {
  name               = format("%s-role", var.lambda_name)
  assume_role_policy = data.aws_iam_policy_document.lambda_role_template.json
}

resource "aws_iam_policy" "lambda_policy" {
  name        = format("%s-policy", var.lambda_name)
  path        = "/"
  description = format("%s lambda policy", var.lambda_name)
  policy      = data.aws_iam_policy_document.lambda_policy_template.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Lambda layers and function

resource "aws_lambda_layer_version" "packages_layer" {
  filename         = "../src/packages.zip"
  layer_name       = format("layer-packages-%s", var.lambda_name)
  source_code_hash = filebase64sha256("../src/packages.zip")

  compatible_runtimes = [
    "python3.8"
  ]
}

resource "aws_lambda_function" "lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.lambda_name
  role             = aws_iam_role.lambda_role.arn
  handler          = var.lambda_handler
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout = var.lambda_timeout
  runtime = "python3.8"

  environment {
    variables = {
      TWITTER_CONSUMER_KEY    = var.twitter_consumer_key
      TWITTER_CONSUMER_SECRET = var.twitter_consumer_secret
      TWITTER_ACCESS_TOKEN    = var.twitter_access_token
      TWITTER_ACCESS_SECRET   = var.twitter_access_secret
    }
  }

  layers = [
    aws_lambda_layer_version.packages_layer.arn
  ]
}

# Cloudwatch schedule

resource "aws_cloudwatch_event_rule" "lambda_event_rule" {
  name                = format("%s-event-rule", var.lambda_handler)
  description         = format("%s event rule", var.lambda_name)
  schedule_expression = var.lambda_schedule
}

resource "aws_cloudwatch_event_target" "lambda_event_target" {
  rule      = aws_cloudwatch_event_rule.lambda_event_rule.name
  target_id = "lambda"
  arn       = aws_lambda_function.lambda.arn
}

resource "aws_lambda_permission" "lambda_cloudwatch_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_event_rule.arn
}
