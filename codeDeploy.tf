resource "aws_codedeploy_app" "front_code_deploy" {
  name = "front-code-deploy"
}

resource "aws_codedeploy_app" "back_code_deploy" {
  name = "back-code-deploy"
}

resource "aws_codedeploy_deployment_group" "front_code_deploy" {
  app_name               = aws_codedeploy_app.front_code_deploy.name
  deployment_group_name  = "front-code-deploy-group"
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
  service_role_arn       = aws_iam_role.code_deploy_role.arn
  autoscaling_groups     = [aws_autoscaling_group.front.name]

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
    }

    green_fleet_provisioning_option {
      action = "COPY_AUTO_SCALING_GROUP"
    }
  }

  load_balancer_info {
    target_group_info {
      name = aws_lb_target_group.external.name
    }
  }

  provisioner "local-exec" {
    command    = file("${path.module}/scripts/delete-asg.sh")
    when       = destroy
    on_failure = continue

    environment = {
      ENV_TYPE = "front-asg"
    }
  }
}

resource "aws_codedeploy_deployment_group" "back_code_deploy" {
  app_name               = aws_codedeploy_app.back_code_deploy.name
  deployment_group_name  = "back-code-deploy-group"
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
  service_role_arn       = aws_iam_role.code_deploy_role.arn
  autoscaling_groups     = [aws_autoscaling_group.back.name]

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
    }

    green_fleet_provisioning_option {
      action = "COPY_AUTO_SCALING_GROUP"
    }
  }

  load_balancer_info {
    target_group_info {
      name = aws_lb_target_group.api.name
    }
  }

  provisioner "local-exec" {
    command    = file("${path.module}/scripts/delete-asg.sh")
    when       = destroy
    on_failure = continue

    environment = {
      ENV_TYPE = "back-asg"
    }
  }
}