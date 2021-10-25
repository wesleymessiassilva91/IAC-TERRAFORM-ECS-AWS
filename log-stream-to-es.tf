resource "aws_lambda_function" "cwl_stream_lambda" {
  filename         = "${path.module}/zip/cwl2eslambda.zip"
  function_name    = "LogsToElasticsearch"
  role             = "${aws_iam_role.lambda_elasticsearch_execution_role.arn}"
  handler          = "index.handler"
  source_code_hash = "${filebase64sha256("${path.module}/zip/cwl2eslambda.zip")}"
  runtime          = "nodejs10.x"
  timeout          = "900"
  
  vpc_config {
    subnet_ids = ["${var.app_subnet_1}","${var.app_subnet_2}"]
      security_group_ids = ["${aws_security_group.ecs_tasks.id}"]
  }

  environment {
    variables = {
      es_endpoint = "${module.elasticsearch.endpoint}"
    }
  }
}

resource "aws_lambda_permission" "cloudwatch_allow" {
  statement_id = "cloudwatch_allow"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.cwl_stream_lambda.arn}"
  principal = "logs.sa-east-1.amazonaws.com"
  source_arn = "${aws_cloudwatch_log_group.mfa_log_group.arn}"
}

resource "aws_cloudwatch_log_subscription_filter" "cloudwatch_logs_to_es" {
  depends_on = ["aws_lambda_permission.cloudwatch_allow"]
  name            = "cloudwatch_logs_to_elasticsearch"
  log_group_name  = "${aws_cloudwatch_log_group.mfa_log_group.name}"
  filter_pattern  = ""
  destination_arn = "${aws_lambda_function.cwl_stream_lambda.arn}"
}