// ECS CPU Policy UP
resource "aws_autoscaling_policy" "autoscaling" {
  name                   = "autoplicy-up-cpu"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.autoscaling.name}"
}

// ECS CPU Policy Down
resource "aws_autoscaling_policy" "autopolicy-down-cpu" {
  name                   = "autoplicy-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 600
  autoscaling_group_name = "${aws_autoscaling_group.autoscaling.name}"
}