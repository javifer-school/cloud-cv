# Modificaciones para AWS Learner Lab

## Resumen de Cambios

Este documento describe las modificaciones realizadas en el proyecto Terraform para que funcione con **AWS Learner Lab**, que tiene restricciones de permisos IAM.

### Problemas Resueltos

1. **Error de creación de roles IAM**: Se eliminó la creación de roles IAM ya que Learner Lab no permite `iam:CreateRole`
2. **Error de CORS en API Gateway**: Se corrigió el wildcard `http://localhost:*` que no es permitido

---

## Cambios Realizados

### 1. Módulo Lambda (`terraform/modules/lambda/`)

#### `variables.tf`
- ✅ **Añadida** variable `lambda_role_arn` para recibir el ARN del rol existente

```hcl
variable "lambda_role_arn" {
  description = "ARN of the existing IAM role for Lambda function"
  type        = string
}
```

#### `main.tf`
- ✅ **Eliminados** recursos `aws_iam_role` y `aws_iam_role_policy`
- ✅ **Actualizada** la función Lambda para usar `var.lambda_role_arn` en lugar de crear un rol nuevo
- ℹ️ Se mantienen CloudWatch Logs, API Gateway y demás recursos

### 2. Variables Principales (`terraform/variables.tf`)

- ✅ **Añadida** variable `lambda_role_arn` como variable obligatoria

```hcl
variable "lambda_role_arn" {
  description = "ARN of the existing IAM role for Lambda (required for AWS Learner Lab)"
  type        = string
}
```

### 3. Configuración Principal (`terraform/main.tf`)

- ✅ **Añadido** parámetro `lambda_role_arn` al módulo Lambda
- ✅ **Corregido** CORS: Cambiado de `http://localhost:*` a `http://localhost:3000`

```hcl
module "lambda" {
  # ...
  lambda_role_arn  = var.lambda_role_arn
  allowed_origins  = ["https://${var.domain_name}", "http://localhost:3000"]
}
```

### 4. Archivo de Variables (`terraform/terraform.tfvars`)

- ✅ **Añadido** el ARN del rol de Learner Lab:

```hcl
lambda_role_arn = "arn:aws:iam::381492142987:role/voclabs"
```

### 5. Script de Utilidad

- ✅ **Creado** `scripts/get-role-arn.sh` para obtener automáticamente el ARN del rol actual

---

## Cómo Usar

### Opción 1: Rol Detectado Automáticamente

El rol `voclabs` ya está configurado en `terraform.tfvars`. Solo ejecuta:

```bash
cd terraform
terraform plan
terraform apply
```

### Opción 2: Obtener el Rol Manualmente

Si necesitas verificar o cambiar el rol:

```bash
# Ejecutar el script de ayuda
./scripts/get-role-arn.sh

# O manualmente con AWS CLI
aws sts get-caller-identity --query Arn --output text
```

Luego actualiza el valor en `terraform/terraform.tfvars`:

```hcl
lambda_role_arn = "arn:aws:iam::TU_ACCOUNT_ID:role/NOMBRE_DEL_ROL"
```

---

## Permisos Necesarios del Rol

El rol de Learner Lab (`voclabs`) debe tener permisos para:

- ✅ Lambda: Crear y gestionar funciones
- ✅ DynamoDB: Acceso a la tabla
- ✅ CloudWatch Logs: Crear log groups y streams
- ✅ API Gateway: Crear y configurar APIs
- ✅ ACM: Gestionar certificados
- ✅ Route53: Gestionar zonas DNS
- ✅ Amplify: Gestionar aplicaciones

El rol de Learner Lab **NO** necesita permisos de IAM (CreateRole, PutRolePolicy, etc.) ya que usamos el rol existente.

---

## Notas Importantes

1. **No se crean roles nuevos**: Todo usa el rol existente de Learner Lab
2. **CORS configurado**: Solo permite `https://cv.aws10.atercates.cat` y `http://localhost:3000`
3. **Región US-EAST-1**: Configurada en `terraform.tfvars` (requerida para ACM con Amplify)

---

## Verificación

Antes de ejecutar Terraform, verifica:

```bash
# Verificar credenciales AWS
aws sts get-caller-identity

# Verificar el plan de Terraform
cd terraform
terraform plan
```

El plan NO debe intentar crear recursos `aws_iam_role` ni `aws_iam_role_policy`.

---

## Troubleshooting

### Error: "lambda_role_arn is required"

Asegúrate de que `terraform.tfvars` contiene:
```hcl
lambda_role_arn = "arn:aws:iam::381492142987:role/voclabs"
```

### Error: CORS wildcard not allowed

Verifica que `allowed_origins` en `main.tf` NO contiene wildcards como `http://localhost:*`

### Error: Access Denied al crear recursos

- Verifica que estás usando el rol de Learner Lab
- Algunos recursos pueden no estar disponibles en Learner Lab (por ejemplo, Amplify en ciertas regiones)

---

**Fecha de modificación**: 9 de enero de 2026
**Versión**: 1.0
