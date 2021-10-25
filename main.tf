data "aws_ami" "latest_ecs" {
  most_recent   = true
  owners        = ["591542846629"] # AWS
  filter {
    name        = "name"
    values      = ["amzn2-ami-ecs-hvm-2*"]
  }
  filter {
    name        = "virtualization-type"
    values      = ["hvm"]
  }
}

data "template_file" "userdata" {
  template      = "${file("${path.module}/ecs.tpl")}"
  vars = {
    ecs_cluster = "${aws_ecs_cluster.ecs_cluster.name}"
  }
}

### ECS ###
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "mfa-ecs"
}

### ASG ###
resource "aws_launch_configuration" "launchconfiguration" {
  name_prefix                 = "mfa-lc-asg"
  security_groups             = ["${aws_security_group.ecs_tasks.id}"]
  key_name                    = "${var.key_name}"
  image_id                    = "${data.aws_ami.latest_ecs.id}"
  instance_type               = "${var.instance_type}"
  iam_instance_profile        = "${aws_iam_instance_profile.instance_profile.id}"
  enable_monitoring           = false
  user_data                   = "${data.template_file.userdata.rendered}"
  associate_public_ip_address = false

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "autoscaling" {
  name                      = "mfa-asg"
  vpc_zone_identifier       = ["${var.app_subnet_1}", "${var.app_subnet_2}"]
  min_size                  = "${var.min_size}"
  max_size                  = "${var.max_size}"
  launch_configuration      = "${aws_launch_configuration.launchconfiguration.name}"
  health_check_type         = "EC2"
  force_delete              = true
  health_check_grace_period = 120
  default_cooldown          = 300
  termination_policies      = ["OldestInstance", "OldestLaunchConfiguration"]
  lifecycle {
    create_before_destroy  = true
  }
  tag {
    key                 = "Name"
    value               = "ECS-Cluster-mfacore"
    propagate_at_launch = true
  }
}

### Autoscaling stop/start ###
resource "aws_autoscaling_schedule" "start" {
  count                  = var.env == "dev" || var.env == "hml" || var.env == "ppr" ? 1:0
  scheduled_action_name  = "start"
  min_size               = "${var.min_size}"
  max_size               = "${var.max_size}"
  desired_capacity       = "${var.min_size}"
  recurrence             = "00 10 * * MON-FRI"
  autoscaling_group_name = aws_autoscaling_group.autoscaling.name
}

resource "aws_autoscaling_schedule" "stop" {
  count                  = var.env == "dev" || var.env == "hml" || var.env == "ppr" ? 1:0
  scheduled_action_name  = "stop"
  min_size               = 0
  max_size               = 0
  desired_capacity       = 0
  recurrence             = "00 22 * * *"
  autoscaling_group_name = aws_autoscaling_group.autoscaling.name
}

### CLOUDWATCH  ###
resource "aws_cloudwatch_log_group" "mfa_log_group" {
  name              = "${var.log_group}"
  retention_in_days = "${var.retention_in_days}"
}

### ALB ###
resource "aws_alb" "alb" {
  name            = "mfa-alb"
  internal        = true
  subnets         = ["${var.dmz_subnet_1}", "${var.dmz_subnet_2}"]
  security_groups = ["${aws_security_group.security_group.id}"]
  enable_http2    = "true"
  idle_timeout    = 300
  tags = {
    pep         = "coremfa"
    sigla       = "mfa"
    descsigla   = "mfacore"
    project     = "mfa"
    region      = "sa-east-1"
    golive      = "false"
    function    = "backend"
    service     = "web"
    owner       = "devops"
  }
}

resource "aws_alb_target_group" "default-target-group" {
  name       = "default"
  port       = 8080
  protocol   = "HTTP"
  vpc_id     = "${var.vpcid}"
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
  }
  deregistration_delay = "60"
  depends_on = ["aws_alb.alb"]
}

resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = "${aws_alb.alb.id}"
  port              = "80"
  protocol          = "HTTP"

   default_action {
     target_group_arn = "${aws_alb_target_group.default-target-group.id}"
     type             = "forward"
   }
}

resource "aws_alb_listener" "listener_https" {
 load_balancer_arn = "${aws_alb.alb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = "${aws_acm_certificate.mfa-acm.arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.default-target-group.id}"
  }
  depends_on = ["aws_acm_certificate.mfa-acm"]
}

output "alb_output" {
  value = "${aws_alb.alb.dns_name}"
}

output "alb_output_listener" {
  value = "${aws_alb_listener.listener_http.arn}"
}