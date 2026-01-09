# =============================================================================
# Amplify Module - Static Website Hosting
# =============================================================================

# -----------------------------------------------------------------------------
# Amplify App
# ---------------------------------------------------------------------------
resource "aws_amplify_app" "cv_app" {
  name       = var.app_name
  repository = var.github_repository

  # GitHub access token (required for private repos)
  access_token = var.github_token != "" ? var.github_token : null

  # Build settings
  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - echo "Starting build..."
        build:
          commands:
            - echo "Building static site..."
      artifacts:
        baseDirectory: curriculum
        files:
          - '**/*'
      cache:
        paths: []
  EOT

  # Environment variables for the frontend
  environment_variables = {
    API_ENDPOINT = var.api_endpoint
    ENV          = var.environment
  }

  # Custom rules for SPA routing
  custom_rule {
    source = "/<*>"
    status = "404-200"
    target = "/index.html"
  }

  custom_rule {
    source = "</^[^.]+$|\\.(?!(css|gif|ico|jpg|jpeg|js|png|txt|svg|woff|woff2|ttf|map|json|webp)$)([^.]+$)/>"
    status = "200"
    target = "/index.html"
  }

  # Enable branch auto-detection
  enable_branch_auto_deletion = true

  tags = {
    Name        = var.app_name
    Environment = var.environment
    Project     = var.project_name
  }
}

# -----------------------------------------------------------------------------
# Amplify Branch (main)
# -----------------------------------------------------------------------------
resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.cv_app.id
  branch_name = var.github_branch

  framework = "Web"
  stage     = "PRODUCTION"

  enable_auto_build = true

  environment_variables = {
    API_ENDPOINT = var.api_endpoint
  }

  tags = {
    Name        = "${var.app_name}-${var.github_branch}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# -----------------------------------------------------------------------------
# Amplify Domain Association
# -----------------------------------------------------------------------------
resource "aws_amplify_domain_association" "cv_domain" {
  app_id      = aws_amplify_app.cv_app.id
  domain_name = var.domain_name

  # Wait for branch to be ready
  wait_for_verification = false

  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = ""
  }

  depends_on = [aws_amplify_branch.main]
}
# -----------------------------------------------------------------------------
# Trigger Initial Deployment
# -----------------------------------------------------------------------------
# This resource triggers an initial deployment of the Amplify app
# The aws_amplify_branch resource has enable_auto_build = true, but it doesn't
# trigger a build on creation. This is a known limitation in the AWS provider.
# Solution: Use null_resource with local-exec to trigger a build via AWS CLI
resource "null_resource" "trigger_initial_deployment" {
  # Triggers ensure this only runs when the branch is created/changed
  triggers = {
    app_id      = aws_amplify_app.cv_app.id
    branch_name = aws_amplify_branch.main.branch_name
  }

  # Execute AWS CLI command to start a deployment job
  provisioner "local-exec" {
    command = "aws amplify start-job --app-id ${aws_amplify_app.cv_app.id} --branch-name ${aws_amplify_branch.main.branch_name} --job-type RELEASE"
  }

  depends_on = [aws_amplify_branch.main]
}
