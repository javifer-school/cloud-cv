# Amplify App
resource "aws_amplify_app" "cv_app" {
  name         = var.app_name
  repository   = var.github_repository
  access_token = var.github_token

  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - echo "Generating runtime configuration..."
            - bash scripts/generate-config.sh
        build:
          commands:
            - echo "Building static site..."
      artifacts:
        baseDirectory: curriculum
        files:
          - '**/*'
  EOT

  environment_variables = {
    API_ENDPOINT = var.api_endpoint
    ENV          = var.environment
  }

  custom_rule {
    source = "/<*>"
    status = "404-200"
    target = "/index.html"
  }

  enable_branch_auto_deletion = true

  tags = {
    Name        = var.app_name
    Environment = var.environment
    Project     = var.project_name
  }
}

# Amplify Branch
resource "aws_amplify_branch" "main" {
  app_id                = aws_amplify_app.cv_app.id
  branch_name           = var.github_branch
  framework             = "Web"
  stage                 = "PRODUCTION"
  enable_auto_build     = true
  environment_variables = { API_ENDPOINT = var.api_endpoint }
  tags = {
    Name        = "${var.app_name}-${var.github_branch}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Amplify Domain Association 
resource "aws_amplify_domain_association" "cv_domain" {
  app_id                = aws_amplify_app.cv_app.id
  domain_name           = var.domain_name
  wait_for_verification = false
  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = ""
  }
  depends_on = [aws_amplify_branch.main]
}

# Trigger Initial Deployment
resource "null_resource" "trigger_initial_deployment" {
  triggers = {
    app_id      = aws_amplify_app.cv_app.id
    branch_name = aws_amplify_branch.main.branch_name
  }
  provisioner "local-exec" {
    command = "aws amplify start-job --app-id ${aws_amplify_app.cv_app.id} --branch-name ${aws_amplify_branch.main.branch_name} --job-type RELEASE"
  }
  depends_on = [aws_amplify_branch.main]
}
