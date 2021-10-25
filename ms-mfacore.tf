resource "aws_ecs_service" "mfa_core" {
  name                               = "mfa-core"
  cluster                            = "${aws_ecs_cluster.ecs_cluster.id}"
  task_definition                    = "${aws_ecs_task_definition.mfa_core.arn}"
  health_check_grace_period_seconds  = "300"
  iam_role                           = "${aws_iam_role.ecs-role.arn}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"
  deployment_maximum_percent         = "${var.deployment_maximum_percent}"
  load_balancer {
    target_group_arn = "${aws_alb_target_group.mfa_core.id}"
    container_name   = "mfa-core"
    container_port   = 8080
  }
  depends_on = ["aws_iam_role.ecs-role"]
}

### TASK DEFINITION ###
data "template_file" "mfa_core" {
  template = "${file("${path.module}/json/mfa_core_definitions.json")}"
  vars = {
    
    microservice                = "mfa-core"
    java_xmx_xms                = "${var.java_xmx_xms_mfacore}"
    containerImage              = "233801601735.dkr.ecr.sa-east-1.amazonaws.com/mfa-core:${var.ms_mfacore_image_version}"
    container_cpu               = "${var.container_cpu_mfacore}"
    container_memory            = "${var.container_memory_mfacore}"
    container_memoryReservation = "${var.container_memoryReservation_mfacore}"
    container_boolean_essential = "true"
    env_container		            = "mfa-${var.env}"
    appdynamics_key             = "${var.appdynamics_key}"
    log_group                   = "${var.log_group}"
    env                         = "${var.env}"
  }
}

resource "aws_ecs_task_definition" "mfa_core" {
  family                = "mfa-core"
  cpu                   = "${var.container_cpu_mfacore}"
  memory                = "${var.container_memory_mfacore}"
  task_role_arn         = "${aws_iam_role.ecs-role.arn}"
  container_definitions = "${data.template_file.mfa_core.rendered}"
}

### ALB ###
resource "aws_alb_target_group" "mfa_core" {
  name       = "mfa-core"
  port       = 8080
  protocol   = "HTTP"
  vpc_id     = "${var.vpcid}"
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
  }
  deregistration_delay = "60"
  depends_on = ["aws_alb.alb"]

  health_check {
    path                = "/mfa/actuator/health"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 10
    matcher             = "200-399"
  }
  tags = {
    pep         = "apollo"
    sigla       = "mfa"
    descsigla   = "apollo"
    project     = "mfa"
    region      = "sa-east-1"
    golive      = "false"
    function    = "backend"
    service     = "web"
    owner       = "devops"
  }
}

resource "aws_alb_listener_rule" "listener_rule_mfa_core_http" {
  listener_arn = "${aws_alb_listener.listener_http.arn}"

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.mfa_core.id}"
  }
  condition {
    field  = "host-header"
    values = ["ms.${var.domain}*"]
  }
}
resource "aws_alb_listener_rule" "listener_rule_mfa_service_https" {
 listener_arn = "${aws_alb_listener.listener_https.arn}"

 action {
   type             = "forward"
   target_group_arn = "${aws_alb_target_group.mfa_core.id}"
 }
 condition {
   field  = "host-header"
   values = ["ms.${var.domain}*"]
 }
}

### AUTO-SCALING ###
# Esse autoscaling é referente ao serviço de ECS, o arquivo autoscaling_policy.tf é referente ao EC2.
#AutoScaling
resource "aws_appautoscaling_target" "mfa_core" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.mfa_core.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = "${aws_iam_role.ecs_auto_scale_role.arn}"
  min_capacity       = "${var.min_capacity_mfacore}"
  max_capacity       = "${var.max_capacity_mfacore}"
}

# Automatically scale capacity up by one
resource "aws_appautoscaling_policy" "mfa_core-up" {
  name               = "mfa_core-up"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.mfa_core.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 120
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  //depends_on = ["${aws_appautoscaling_target.mfa_core}"]
}

// CPU
// CloudWatch alarm that triggers the autoscaling up policy
resource "aws_cloudwatch_metric_alarm" "service_mfa_core_cpu_high" {
  alarm_name          = "mfa_core_cpu_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "85"

  dimensions = {
    ClusterName = "${aws_ecs_cluster.ecs_cluster.name}"
    ServiceName = "${aws_ecs_service.mfa_core.name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.mfa_core-up.arn}"]
}

// Automatically scale capacity down by one
resource "aws_appautoscaling_policy" "mfa_core-down" {
  name               = "mfa_core-down"
  policy_type        = "StepScaling"
  resource_id        = "${aws_appautoscaling_target.mfa_core.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.mfa_core.scalable_dimension}"
  service_namespace  = "${aws_appautoscaling_target.mfa_core.service_namespace}"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 120
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

# CloudWatch alarm that triggers the autoscaling down policy
resource "aws_cloudwatch_metric_alarm" "mfa_core_cpu_low" {
  alarm_name          = "mfa_core_cpu_utilization_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "180"
  statistic           = "Average"
  threshold           = "25"

  dimensions = {
    ClusterName = "${aws_ecs_cluster.ecs_cluster.name}"
    ServiceName = "${aws_ecs_service.mfa_core.name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.mfa_core-down.arn}"]
}

// Memory
// CloudWatch alarm mfa-core
resource "aws_cloudwatch_metric_alarm" "service_mfa_core_memory" {
  alarm_name          = "mfa_core_memory_utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "90"

  dimensions = {
    ClusterName = "${aws_ecs_cluster.ecs_cluster.name}"
    ServiceName = "${aws_ecs_service.mfa_core.name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.mfa_core-up.arn}"]
  alarm_description = "Service mfa-core Alto consumo de Memoria RAM"
  actions_enabled = true
}

### ROUTE53 ###
resource "aws_route53_record" "mfa_core" {
 zone_id = "${data.aws_route53_zone.primary.zone_id}"
 name    = "ms.${var.domain}"
 type    = "CNAME"
 ttl     = "300"
 records        = ["${aws_alb.alb.dns_name}"]
}
