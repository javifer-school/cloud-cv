# =============================================================================
# Cloud CV - Makefile
# =============================================================================
# Comandos útiles para gestionar el proyecto Cloud CV

.PHONY: help check test deploy-local clean init fmt validate

# Variables
PYTHON := python3
PIP := $(PYTHON) -m pip
PYTEST := $(PYTHON) -m pytest
TERRAFORM := terraform
AWS := aws

# Colores para output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

# =============================================================================
# Help
# =============================================================================
help: ## Mostrar esta ayuda
	@echo "$(BLUE)Cloud CV - Comandos Disponibles$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

# =============================================================================
# Setup & Installation
# =============================================================================
init: ## Inicializar proyecto (instalar dependencias)
	@echo "$(BLUE)Instalando dependencias...$(NC)"
	$(PIP) install --upgrade pip
	$(PIP) install -r lambda/tests/requirements-test.txt
	@echo "$(GREEN)✓ Dependencias instaladas$(NC)"

# =============================================================================
# Pre-deployment Checks
# =============================================================================
check: ## Ejecutar verificaciones pre-deployment
	@echo "$(BLUE)Ejecutando verificaciones...$(NC)"
	@bash scripts/pre-deploy-check.sh

# =============================================================================
# Testing
# =============================================================================
test: ## Ejecutar tests de Lambda
	@echo "$(BLUE)Ejecutando tests...$(NC)"
	cd lambda && $(PYTEST) tests/ -v

test-cov: ## Ejecutar tests con coverage
	@echo "$(BLUE)Ejecutando tests con coverage...$(NC)"
	cd lambda && $(PYTEST) tests/ -v --cov=visit_counter --cov-report=html --cov-report=term-missing
	@echo "$(GREEN)✓ Coverage report generado en lambda/htmlcov/index.html$(NC)"

test-watch: ## Ejecutar tests en modo watch
	@echo "$(BLUE)Ejecutando tests en modo watch...$(NC)"
	cd lambda && $(PYTEST) tests/ -v --looponfail

# =============================================================================
# Terraform
# =============================================================================
tf-init: ## Inicializar Terraform
	@echo "$(BLUE)Inicializando Terraform...$(NC)"
	cd terraform && $(TERRAFORM) init

tf-fmt: ## Formatear código Terraform
	@echo "$(BLUE)Formateando código Terraform...$(NC)"
	cd terraform && $(TERRAFORM) fmt -recursive
	@echo "$(GREEN)✓ Código formateado$(NC)"

tf-validate: ## Validar configuración Terraform
	@echo "$(BLUE)Validando Terraform...$(NC)"
	cd terraform && $(TERRAFORM) init -backend=false && $(TERRAFORM) validate
	@echo "$(GREEN)✓ Configuración válida$(NC)"

tf-plan: ## Ver plan de cambios Terraform
	@echo "$(BLUE)Generando plan...$(NC)"
	cd terraform && $(TERRAFORM) plan

tf-apply: ## Aplicar cambios Terraform
	@echo "$(YELLOW)⚠ Esto desplegará cambios en AWS$(NC)"
	@read -p "¿Continuar? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		cd terraform && $(TERRAFORM) apply; \
	fi

tf-destroy: ## Destruir infraestructura Terraform
	@echo "$(RED)⚠⚠⚠ CUIDADO: Esto destruirá toda la infraestructura$(NC)"
	@read -p "¿Estás SEGURO? Escribe 'destroy' para confirmar: " confirm; \
	if [ "$$confirm" = "destroy" ]; then \
		cd terraform && $(TERRAFORM) destroy; \
	else \
		echo "$(GREEN)Cancelado$(NC)"; \
	fi

tf-output: ## Mostrar outputs de Terraform
	@cd terraform && $(TERRAFORM) output

# =============================================================================
# Lambda Development
# =============================================================================
lambda-package: ## Empaquetar Lambda para deployment
	@echo "$(BLUE)Empaquetando Lambda...$(NC)"
	cd lambda/visit_counter && zip -r ../deployment-package.zip .
	@echo "$(GREEN)✓ Package creado: lambda/deployment-package.zip$(NC)"

lambda-deploy: lambda-package ## Desplegar Lambda a AWS (requiere infraestructura existente)
	@echo "$(BLUE)Desplegando Lambda...$(NC)"
	$(AWS) lambda update-function-code \
		--function-name cv-visit-counter \
		--zip-file fileb://lambda/deployment-package.zip
	@echo "$(GREEN)✓ Lambda desplegada$(NC)"

lambda-logs: ## Ver logs de Lambda en tiempo real
	@echo "$(BLUE)Mostrando logs de Lambda...$(NC)"
	$(AWS) logs tail /aws/lambda/cv-visit-counter --follow

lambda-invoke: ## Invocar Lambda de prueba
	@echo "$(BLUE)Invocando Lambda...$(NC)"
	@echo '{"requestContext":{"http":{"method":"GET","sourceIp":"127.0.0.1"}},"headers":{}}' > /tmp/test-event.json
	$(AWS) lambda invoke \
		--function-name cv-visit-counter \
		--payload file:///tmp/test-event.json \
		/tmp/response.json
	@cat /tmp/response.json | jq .
	@rm /tmp/test-event.json /tmp/response.json

# =============================================================================
# AWS Status
# =============================================================================
aws-status: ## Ver estado de recursos AWS
	@echo "$(BLUE)Estado de recursos AWS:$(NC)"
	@echo ""
	@echo "$(YELLOW)Lambda:$(NC)"
	@$(AWS) lambda get-function --function-name cv-visit-counter --query 'Configuration.[FunctionName,Runtime,LastModified]' --output table 2>/dev/null || echo "  No encontrada"
	@echo ""
	@echo "$(YELLOW)DynamoDB:$(NC)"
	@$(AWS) dynamodb describe-table --table-name cv-visit-counter --query 'Table.[TableName,TableStatus,ItemCount]' --output table 2>/dev/null || echo "  No encontrada"
	@echo ""
	@echo "$(YELLOW)Amplify:$(NC)"
	@$(AWS) amplify list-apps --query 'apps[?name==`cloud-cv`].[name,defaultDomain]' --output table 2>/dev/null || echo "  No encontrada"

# =============================================================================
# Git
# =============================================================================
git-status: ## Ver estado de Git
	@git status

git-diff: ## Ver diferencias
	@git diff

git-push: ## Push a GitHub (activa CI/CD)
	@echo "$(YELLOW)Esto activará los workflows de CI/CD$(NC)"
	@git status
	@read -p "¿Push a origin/main? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		git push origin main; \
	fi

# =============================================================================
# Cleanup
# =============================================================================
clean: ## Limpiar archivos generados
	@echo "$(BLUE)Limpiando archivos generados...$(NC)"
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "htmlcov" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name ".coverage" -delete 2>/dev/null || true
	find . -type f -name "coverage.xml" -delete 2>/dev/null || true
	rm -rf lambda/*.zip 2>/dev/null || true
	rm -rf terraform/.terraform 2>/dev/null || true
	rm -rf terraform/*.tfstate* 2>/dev/null || true
	rm -rf terraform/tfplan 2>/dev/null || true
	@echo "$(GREEN)✓ Limpieza completada$(NC)"

clean-all: clean ## Limpieza profunda (incluye .terraform)
	@echo "$(BLUE)Limpieza profunda...$(NC)"
	rm -rf terraform/.terraform.lock.hcl 2>/dev/null || true
	@echo "$(GREEN)✓ Limpieza profunda completada$(NC)"

# =============================================================================
# Development
# =============================================================================
dev-setup: init tf-init ## Setup completo para desarrollo
	@echo "$(GREEN)✓ Entorno de desarrollo configurado$(NC)"

dev-test: test-cov ## Ejecutar tests y abrir coverage
	@echo "$(BLUE)Abriendo reporte de coverage...$(NC)"
	@command -v xdg-open > /dev/null && xdg-open lambda/htmlcov/index.html || \
	 command -v open > /dev/null && open lambda/htmlcov/index.html || \
	 echo "$(YELLOW)Abre manualmente: lambda/htmlcov/index.html$(NC)"

# =============================================================================
# Default
# =============================================================================
.DEFAULT_GOAL := help
