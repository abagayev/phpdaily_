# Data

data "template_file" "lambda_role_template" {
  template = "${file(format("%s/templates/lambda_role_template", path.module))}"
}

data "template_file" "lambda_policy_template" {
  template = "${file(format("%s/templates/lambda_policy_template", path.module))}"
}

data "local_file" "twitter_access_token" {
  filename = "secrets/twitter_access_token.txt"
}

data "local_file" "twitter_access_secret" {
  filename = "secrets/twitter_access_secret.txt"
}

data "local_file" "twitter_consumer_key" {
  filename = "secrets/twitter_consumer_key.txt"
}

data "local_file" "twitter_consumer_secret" {
  filename = "secrets/twitter_consumer_secret.txt"
}

data "archive_file" "lambda_zip" {
  type = "zip"
  source_file = "../src/lambda_function.py"
  output_path = "tmp/lambda.zip"
}

# IAM

resource "aws_iam_role" "lambda_role" {
  name = "${var.lambda_name}-role"
  assume_role_policy = "${data.template_file.lambda_role_template.rendered}"
}

resource "aws_iam_policy" "lambda_policy" {
  name = "${var.lambda_name}-policy"
  path = "/"
  description = "${var.lambda_name} lambda policy"
  policy = "${data.template_file.lambda_policy_template.rendered}"
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role = "${aws_iam_role.lambda_role.name}"
  policy_arn = "${aws_iam_policy.lambda_policy.arn}"
}

# Lambda layers and function

resource "aws_lambda_layer_version" "packages_layer" {
  filename = "../src/packages.zip"
  layer_name = "layer-packages-${var.lambda_name}"

  compatible_runtimes = [
    "python3.6"
  ]
}

resource "aws_lambda_function" "lambda" {
  filename = "${data.archive_file.lambda_zip.output_path}"
  function_name = "${var.lambda_name}"
  role = "${aws_iam_role.lambda_role.arn}"
  handler = "${var.lambda_handler}"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"

  timeout = "${var.lambda_timeout}"
  runtime = "python3.6"

  environment {
    variables = {
      TWITTER_CONSUMER_KEY = "${chomp(data.local_file.twitter_consumer_key.content)}",
      TWITTER_CONSUMER_SECRET = "${chomp(data.local_file.twitter_consumer_secret.content)}",
      TWITTER_ACCESS_TOKEN = "${chomp(data.local_file.twitter_access_token.content)}",
      TWITTER_ACCESS_SECRET = "${chomp(data.local_file.twitter_access_secret.content)}",
    }
  }

  layers = [
    "${aws_lambda_layer_version.packages_layer.arn}"
  ]
}

# Cloudwatch schedule

resource "aws_cloudwatch_event_rule" "lambda_event_rule" {
  name = "${var.lambda_handler}-event-rule"
  description = "${var.lambda_name} event rule"
  schedule_expression = "${var.lambda_schedule}"
}

resource "aws_cloudwatch_event_target" "lambda_event_target" {
  rule = "${aws_cloudwatch_event_rule.lambda_event_rule.name}"
  target_id = "lambda"
  arn = "${aws_lambda_function.lambda.arn}"
}

resource "aws_lambda_permission" "lambda_cloudwatch_permission" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda.function_name}"
  principal = "events.amazonaws.com"
  source_arn = "${aws_cloudwatch_event_rule.lambda_event_rule.arn}"
}
