# 🛠️ Comandos Útiles - Cloud CV

## 📋 Quick Reference

### Verificación Rápida

```bash
# Verificar todo antes de desplegar
make check

# Ver ayuda de comandos disponibles
make help
```

---

## 🧪 Testing

### Tests Locales

```bash
# Ejecutar todos los tests
make test

# Tests con coverage
make test-cov

# Tests en modo watch (auto-reload)
make test-watch

# Abrir reporte de coverage en navegador
make dev-test
```

### Manual

```bash
cd lambda

# Instalar dependencias
pip install -r tests/requirements-test.txt

# Ejecutar tests
pytest tests/ -v

# Con coverage detallado
pytest tests/ -v --cov=visit_counter --cov-report=term-missing

# Test específico
pytest tests/test_handler.py::TestGetVisitorIP -v

# Con debugging
pytest tests/ -v -s
```

---

## 🏗️ Terraform

### Comandos Básicos

```bash
# Inicializar
make tf-init

# Formatear código
make tf-fmt

# Validar
make tf-validate

# Ver plan
make tf-plan

# Aplicar cambios
make tf-apply

# Destruir todo (¡CUIDADO!)
make tf-destroy

# Ver outputs
make tf-output
```

### Manual

```bash
cd terraform

# Inicializar (primera vez)
terraform init

# Ver plan de cambios
terraform plan -var="github_token=YOUR_TOKEN"

# Aplicar cambios
terraform apply -var="github_token=YOUR_TOKEN"

# Aplicar auto-aprobado
terraform apply -var="github_token=YOUR_TOKEN" -auto-approve

# Ver recursos creados
terraform state list

# Ver detalles de un recurso
terraform state show module.lambda.aws_lambda_function.visit_counter

# Ver outputs
terraform output
terraform output -json

# Destruir infraestructura
terraform destroy -var="github_token=YOUR_TOKEN"
```

---

## 🔨 Lambda Development

### Packaging

```bash
# Crear package
make lambda-package

# Desplegar a AWS
make lambda-deploy
```

### Manual

```bash
cd lambda/visit_counter

# Crear deployment package
zip -r ../deployment-package.zip .

# Actualizar función en AWS
aws lambda update-function-code \
    --function-name cv-visit-counter \
    --zip-file fileb://../deployment-package.zip

# Esperar a que se actualice
aws lambda wait function-updated \
    --function-name cv-visit-counter
```

### Logs y Testing

```bash
# Ver logs en tiempo real
make lambda-logs

# Invocar función
make lambda-invoke

# Manual - Invocar con payload custom
echo '{
  "requestContext": {
    "http": {
      "method": "POST",
      "sourceIp": "192.168.1.100"
    }
  },
  "headers": {
    "origin": "https://cv.aws10.atercates.cat"
  }
}' > test-event.json

aws lambda invoke \
    --function-name cv-visit-counter \
    --payload file://test-event.json \
    response.json

cat response.json | jq .
```

---

## 📊 AWS Monitoring

### Estado de Recursos

```bash
# Ver estado general
make aws-status

# Lambda específica
aws lambda get-function \
    --function-name cv-visit-counter

# DynamoDB
aws dynamodb describe-table \
    --table-name cv-visit-counter

# Amplify
aws amplify list-apps

# API Gateway
aws apigatewayv2 get-apis
```

### Logs

```bash
# Logs de Lambda
aws logs tail /aws/lambda/cv-visit-counter --follow

# Logs de API Gateway
aws logs tail /aws/apigateway/cloud-cv-api --follow

# Buscar errores en logs
aws logs filter-log-events \
    --log-group-name /aws/lambda/cv-visit-counter \
    --filter-pattern "ERROR"
```

### DynamoDB

```bash
# Ver items en tabla
aws dynamodb scan \
    --table-name cv-visit-counter \
    --max-items 10

# Obtener item específico
aws dynamodb get-item \
    --table-name cv-visit-counter \
    --key '{"visitor_ip":{"S":"192.168.1.1"}}'

# Contar items
aws dynamodb scan \
    --table-name cv-visit-counter \
    --select COUNT
```

---

## 🚀 Deployment

### CI/CD via GitHub Actions

```bash
# Push activa workflows automáticamente
git add .
git commit -m "feat: Update CV content"
git push origin main

# Ver workflows en ejecución
gh run list

# Ver logs de último run
gh run view --log

# Re-ejecutar workflow fallido
gh run rerun <run-id>
```

### Manual Deploy Steps

```bash
# 1. Tests locales
make test-cov

# 2. Validar Terraform
make tf-validate

# 3. Ver plan
make tf-plan

# 4. Aplicar (con confirmación)
make tf-apply

# 5. Actualizar Lambda
make lambda-deploy

# 6. Verificar
make aws-status
```

---

## 🧹 Cleanup

### Limpieza Local

```bash
# Limpiar archivos generados
make clean

# Limpieza profunda
make clean-all
```

### Manual

```bash
# Python cache
find . -type d -name "__pycache__" -exec rm -rf {} +
find . -type f -name "*.pyc" -delete
find . -type d -name ".pytest_cache" -exec rm -rf {} +

# Coverage
rm -rf lambda/htmlcov/
rm -f lambda/.coverage

# Lambda packages
rm -f lambda/*.zip

# Terraform
rm -rf terraform/.terraform/
rm -f terraform/*.tfstate*
```

---

## 🔍 Debugging

### Lambda Local Testing

```bash
# Crear evento de prueba
cat > test-event.json << EOF
{
  "version": "2.0",
  "routeKey": "GET /visits",
  "rawPath": "/visits",
  "headers": {
    "x-forwarded-for": "127.0.0.1"
  },
  "requestContext": {
    "http": {
      "method": "GET",
      "sourceIp": "127.0.0.1"
    }
  }
}
EOF

# Ejecutar localmente con Python
cd lambda/visit_counter
python -c "
import json
from handler import lambda_handler

with open('../../test-event.json') as f:
    event = json.load(f)

result = lambda_handler(event, None)
print(json.dumps(result, indent=2))
"
```

### Ver Variables de Entorno Lambda

```bash
aws lambda get-function-configuration \
    --function-name cv-visit-counter \
    --query 'Environment'
```

### Terraform Debug

```bash
# Logs detallados
TF_LOG=DEBUG terraform plan

# Solo logs de Terraform
TF_LOG=TRACE terraform apply

# Guardar logs en archivo
TF_LOG=DEBUG TF_LOG_PATH=./terraform.log terraform plan
```

---

## 📝 Git Workflows

### Desarrollo con Branches

```bash
# Crear feature branch
git checkout -b feature/new-section

# Hacer cambios
git add curriculum/index.html
git commit -m "feat: Add projects section"

# Push y crear PR
git push origin feature/new-section
gh pr create --fill

# Merge cuando esté aprobado
gh pr merge --auto --squash
```

### Hotfix

```bash
# Crear hotfix branch
git checkout -b hotfix/fix-counter

# Fix rápido
git add lambda/visit_counter/handler.py
git commit -m "fix: Correct IP extraction logic"

# Push directo a main (o crear PR)
git push origin hotfix/fix-counter
gh pr create --base main --fill
```

---

## 🎯 Productividad

### Aliases Útiles

Añadir a `~/.bashrc` o `~/.zshrc`:

```bash
# Cloud CV aliases
alias cv='cd ~/School/ASIX2/Cloud/cloud-cv'
alias cvt='cd ~/School/ASIX2/Cloud/cloud-cv && make test'
alias cvs='cd ~/School/ASIX2/Cloud/cloud-cv && make aws-status'
alias cvl='cd ~/School/ASIX2/Cloud/cloud-cv && make lambda-logs'
```

### Watch Commands

```bash
# Monitorear logs en tiempo real
watch -n 2 'aws lambda invoke --function-name cv-visit-counter --payload "{}" /tmp/out.json && cat /tmp/out.json | jq'

# Ver estado de DynamoDB
watch -n 5 'aws dynamodb scan --table-name cv-visit-counter --select COUNT'
```

---

## 🆘 Troubleshooting Common Issues

### Lambda no se actualiza

```bash
# Forzar actualización
aws lambda update-function-code \
    --function-name cv-visit-counter \
    --zip-file fileb://lambda/deployment-package.zip \
    --publish

# Verificar versión
aws lambda get-function --function-name cv-visit-counter \
    --query 'Configuration.LastModified'
```

### Terraform state lock

```bash
# Si el state está bloqueado
cd terraform
terraform force-unlock <LOCK_ID>
```

### DynamoDB no responde

```bash
# Verificar tabla
aws dynamodb describe-table --table-name cv-visit-counter

# Test básico
aws dynamodb put-item \
    --table-name cv-visit-counter \
    --item '{"visitor_ip":{"S":"test"},"visit_count":{"N":"1"}}'
```

---

**Tip:** Usa `make help` para ver todos los comandos disponibles del Makefile.
