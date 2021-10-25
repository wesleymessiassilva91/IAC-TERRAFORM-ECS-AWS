// ECS CPU Alarm UP
resource "aws_cloudwatch_metric_alarm" "cpualarm" {
  alarm_name          = "high-ecs-utilization-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = (var.env == "prd" ? "70" : "75")

  dimensions = {
    ClusterName = "${aws_ecs_cluster.ecs_cluster.name}"
  }

  alarm_description = "This metric monitor EC2 instance cpu utilization"
  actions_enabled = true
  alarm_actions     = ["${aws_autoscaling_policy.autoscaling.arn}"]
}

// ECS CPU Alarm Down
resource "aws_cloudwatch_metric_alarm" "cpualarm-down" {
  alarm_name          = "low-ecs-utilization-cpu-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "50"

  dimensions = {
    ClusterName = "${aws_ecs_cluster.ecs_cluster.name}"
  }

  alarm_description = "This metric monitor EC2 instance cpu utilization"
  actions_enabled = true
  alarm_actions     = ["${aws_autoscaling_policy.autopolicy-down-cpu.arn}"]
}

// DynamoDB Table clientes
resource "aws_cloudwatch_metric_alarm" "CloudWatch_cliente_Read" {
  alarm_name                = "DynamoDB_cliente_ProvisionedRead"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "ProvisionedReadCapacityUnits"
  namespace                 = "AWS/DynamoDB"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors DynamoDB ReadCapacity"
  insufficient_data_actions = []
  dimensions = {
   TableName = "${aws_dynamodb_table.cliente.name}"
  }

}

resource "aws_cloudwatch_metric_alarm" "CloudWatch_cliente_Write" {
  alarm_name                = "DynamoDB_cliente_ProvisionedWrite"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "ProvisionedWriteCapacityUnits"
  namespace                 = "AWS/DynamoDB"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors DynamoDB WriteCapacity"
  insufficient_data_actions = []
  dimensions = {
   TableName = "${aws_dynamodb_table.cliente.name}"
  }

}

// DynamoDB  Table Whitelist
resource "aws_cloudwatch_metric_alarm" "CloudWatch_whitelist_Read" {
  alarm_name                = "DynamoDB_whitelist_ProvisionedRead"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "ProvisionedReadCapacityUnits"
  namespace                 = "AWS/DynamoDB"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors DynamoDB ReadCapacity"
  insufficient_data_actions = []
  dimensions = {
   TableName = "${aws_dynamodb_table.whitelist.name}"
  }

}

resource "aws_cloudwatch_metric_alarm" "CloudWatch_whitelist_Write" {
  alarm_name                = "DynamoDB_whitelist_ProvisionedWrite"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "ProvisionedWriteCapacityUnits"
  namespace                 = "AWS/DynamoDB"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors DynamoDB WriteCapacity"
  insufficient_data_actions = []
  dimensions = {
   TableName = "${aws_dynamodb_table.whitelist.name}"
  }

}