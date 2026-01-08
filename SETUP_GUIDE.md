# 🔐 Configuración de Variables y Preparativos Pre-despliegue

## 📋 Resumen

Antes de desplegar la infraestructura necesitas:

1. **AWS:** Crear IAM user + obtener credenciales
2. **GitHub:** Configurar secretos
3. **Cloudflare:** Configurar token API (opcional pero recomendado)
4. **Local:** Variables de entorno en tu máquina
5. **DNS:** Verificar zona en Route53

---

## 🔐 Variables de Entorno Locales

### En tu Máquina de Desarrollo

Añade a `~/.bashrc`, `~/.zshrc` o `~/.fish/config.fish`:

```bash
# AWS Credentials
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="wJal..."
export AWS_REGION="eu-west-1"
export AWS_ACCOUNT_ID="123456789012"

# Terraform Variables
export TF_VAR_github_token="ghp_..."
export TF_VAR_domain_name="cv.aws10.atercates.cat"
export TF_VAR_hosted_zone_name="atercates.cat"

# Cloudflare (opcional)
export CLOUDFLARE_API_TOKEN="your_token_here"
export CF_API_TOKEN="your_token_here"  # Alias para flarectl
```

### Archivo `.env` Local (NO hacer commit)

Crear `.env.local` (añadido a `.gitignore`):

```bash
# AWS
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=wJal...
AWS_REGION=eu-west-1
AWS_ACCOUNT_ID=123456789012

# Terraform
TF_VAR_github_token=ghp_...
TF_VAR_domain_name=cv.aws10.atercates.cat
TF_VAR_hosted_zone_name=atercates.cat

# Cloudflare
CLOUDFLARE_API_TOKEN=your_token_here
```

### Cargar Variables Locales

```bash
# Desde bash/zsh
source .env.local

# O automáticamente (si usas direnv)
cp .env.local .envrc
direnv allow
```

---

## 🔑 Credenciales AWS

### 1. Crear IAM User en AWS

**En AWS Console:**

1. Ve a **IAM → Users → Create user**
2. Nombre: `cloud-cv-deployer`
3. Enable: **Console and programmatic access**
4. Click **Next**

**Asignar Permisos:**

1. Create policy personalizada o usar estas políticas existentes:
   - ✅ `AWSLambdaFullAccess`
   - ✅ `AmazonDynamoDBFullAccess`
   - ✅ `AWSAmplifyFullAccess`
   - ✅ `AmazonRoute53FullAccess`
   - ✅ `AWSCertificateManagerFullAccess`
   - ✅ `CloudFrontFullAccess`
   - ✅ `AWSCloudFormationFullAccess`
   - ✅ `IAMFullAccess`
   - ✅ `CloudWatchLogsFullAccess`
   - ✅ `AWSAPIGatewayFullAccess`

**Política Mínima (Restrictiva):**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:*",
        "apigateway:*",
        "dynamodb:*",
        "amplify:*",
        "route53:*",
        "acm:*",
        "iam:CreateRole",
        "iam:PutRolePolicy",
        "iam:PassRole",
        "iam:GetRole",
        "logs:*",
        "s3:*"
      ],
      "Resource": "*"
    }
  ]
}
```

2. Click **Create user**
3. **Guardar Access Key e Secret Key** en lugar seguro

### 2. Obtener Credenciales

**En la página de nuevo usuario:**

1. Sección **Security credentials**
2. Click **Create access key**
3. Selecciona: **Command Line Interface (CLI)**
4. Click **Create access key**
5. **Copiar:**
   - `Access Key ID` (AKIA...)
   - `Secret Access Key` (wJal...)

⚠️ **IMPORTANTE:** Descargar CSV - nunca volverás a ver el Secret Key

### Verificar Credenciales Locales

```bash
# Guardar credenciales en ~/.aws/credentials
aws configure

# O manual:
cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = AKIA...
aws_secret_access_key = wJal...
EOF

# Verificar que funcionan
aws sts get-caller-identity
# Salida esperada:
# {
#     "UserId": "AIDAI...",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/cloud-cv-deployer"
# }
```

---

## 🐙 GitHub Secrets

### Configurar en GitHub

**Ve a:** `Settings → Secrets and variables → Actions`

Añade estos secretos (de forma **individual**):

| Secreto | Valor | Ejemplo |
|---------|-------|---------|
| `AWS_ACCESS_KEY_ID` | Access Key de IAM | `AKIA2BXNZ3EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | Secret Key de IAM | `wJalrXUtnFEMI/K7MDENG/bPxRfCHEXAMPLEKEY` |
| `GH_TOKEN_AMPLIFY` | GitHub Personal Token | `ghp_5g6h7j8k9l0m1n2o3p4q5r6s7t8u9v0w` |

### Crear GitHub Personal Access Token

1. Ve a **GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)**
2. Click **Generate new token (classic)**
3. Nombre: `Cloud CV Amplify Token`
4. Selecciona scopes:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `user:email` (Access user email addresses)
5. Click **Generate token**
6. **Copiar inmediatamente** (solo aparece una vez)

### Verificar Secretos

```bash
# Con GitHub CLI
gh secret list

# Actualizar secreto
gh secret set AWS_ACCESS_KEY_ID -b "AKIA..."
```

---

## ☁️ Configuración AWS Pre-despliegue

### 1. Verificar Zona DNS en Route53

```bash
# Listar hosted zones
aws route53 list-hosted-zones-by-name --query "HostedZones[*].[Name,Id]" --output table

# Debe salir:
# Name              | Id
# atercates.cat.    | /hostedzone/Z1234ABCD
```

Si no existe la zona:

```bash
# Crear zona DNS
aws route53 create-hosted-zone \
    --name atercates.cat \
    --caller-reference $(date +%s)

# Verás los nameservers - actualizar en tu registrador de dominio
```

### 2. S3 Backend para Terraform State (Opcional pero Recomendado)

```bash
# Crear bucket S3 para guardar estado Terraform
aws s3api create-bucket \
    --bucket cloud-cv-terraform-state-$(date +%s) \
    --region eu-west-1 \
    --create-bucket-configuration LocationConstraint=eu-west-1

# Habilitar versionado
aws s3api put-bucket-versioning \
    --bucket cloud-cv-terraform-state-xxx \
    --versioning-configuration Status=Enabled

# Habilitar encriptación
aws s3api put-bucket-encryption \
    --bucket cloud-cv-terraform-state-xxx \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }'

# Bloquear acceso público
aws s3api put-public-access-block \
    --bucket cloud-cv-terraform-state-xxx \
    --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

Luego actualizar `terraform/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "cloud-cv-terraform-state-xxx"
    key            = "terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

### 3. Crear tabla DynamoDB para Locks (Opcional)

```bash
# Para un S3 backend más seguro
aws dynamodb create-table \
    --table-name terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region eu-west-1
```

### 4. Crear VPC Default (si no existe)

```bash
# Verificar VPC default
aws ec2 describe-vpcs --filters "Name=isDefault,Values=true"

# Si no existe, crear
aws ec2 create-default-vpc
```

### 5. Crear Key Pair SSH (Opcional, para futuros Bastion Hosts)

```bash
# Crear key pair
aws ec2 create-key-pair \
    --key-name cloud-cv-deployer \
    --query 'KeyMaterial' \
    --output text > cloud-cv-deployer.pem

# Permisos seguros
chmod 400 cloud-cv-deployer.pem
```

---

## 🔗 Cloudflare (Opcional pero Recomendado)

### Si usas Cloudflare como DNS

#### 1. Obtener API Token

**En Cloudflare Console:**

1. Ve a **My Profile → API Tokens**
2. Click **Create Token**
3. Selecciona template: **Edit zone DNS**
4. Configure:
   - **Permissions:**
     - ✅ Zone.DNS (Edit)
     - ✅ Zone.Zone Settings (Read)
   - **Zone Resources:** `atercates.cat`
5. Click **Continue to summary**
6. Click **Create Token**
7. **Copiar token** (aparece solo una vez)

#### 2. Configurar Variables

```bash
# En ~/.bashrc o ~/.zshrc
export CLOUDFLARE_API_TOKEN="your_token_here"
export CF_API_TOKEN="your_token_here"

# En terraform/terraform.tfvars
cloudflare_api_token = "your_token_here"
```

#### 3. Verificar Token

```bash
# Con curl
curl -X GET "https://api.cloudflare.com/client/v4/user" \
    -H "Authorization: Bearer YOUR_TOKEN" \
    -H "Content-Type: application/json"

# Respuesta esperada: status: "success"
```

---

## 📝 Archivo de Configuración Terraform

### Crear `terraform.tfvars`

```hcl
# Copiar desde el ejemplo
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Editar con tus valores
cat terraform/terraform.tfvars
```

### Contenido Completo

```hcl
# AWS
aws_region = "eu-west-1"

# Project
project_name = "cloud-cv"
environment  = "production"

# Domain
domain_name      = "cv.aws10.atercates.cat"
hosted_zone_name = "atercates.cat"

# GitHub
github_repository = "https://github.com/javifer-school/cloud-cv"
github_branch     = "main"
github_token      = "ghp_..." # ← Reemplazar con tu token

# DynamoDB
dynamodb_table_name = "cv-visit-counter"

# Lambda
lambda_function_name = "cv-visit-counter"
lambda_runtime       = "python3.11"
lambda_memory        = 128
lambda_timeout       = 10
```

---

## ✅ Checklist Pre-despliegue

### Localmente

- [ ] AWS Access Key configurado
- [ ] AWS Secret Key configurado
- [ ] Credenciales probadas: `aws sts get-caller-identity`
- [ ] GitHub token generado
- [ ] Variables en `~/.bashrc` o `~/.zshrc`
- [ ] `terraform/terraform.tfvars` creado y configurado
- [ ] `.gitignore` incluye `.tfstate`, `.env.local`, credenciales

### En GitHub

- [ ] Secreto `AWS_ACCESS_KEY_ID` configurado
- [ ] Secreto `AWS_SECRET_ACCESS_KEY` configurado
- [ ] Secreto `GH_TOKEN_AMPLIFY` configurado
- [ ] Verificar permisos: `gh secret list`

### En AWS

- [ ] IAM user creado: `cloud-cv-deployer`
- [ ] Access Keys generadas y guardadas
- [ ] Permisos asignados
- [ ] Hosted zone `atercates.cat` en Route53
- [ ] S3 bucket para Terraform state (opcional)
- [ ] DynamoDB locks table (opcional)
- [ ] Account ID anotado

### En Cloudflare (si aplica)

- [ ] API Token generado
- [ ] Token verificado
- [ ] Zona `atercates.cat` configurada

### Localmente - Final

- [ ] `make check` pasa todos los checks
- [ ] `terraform validate` no da errores
- [ ] Tests pasan: `make test`
- [ ] `.git` inicializado y remote configurado

---

## 🚀 Orden de Ejecución Recomendado

### 1️⃣ Fase Local (Tu Máquina)

```bash
# 1. Crear credenciales AWS
# (en AWS Console: IAM → Users)

# 2. Guardar credenciales localmente
aws configure
# O manual en ~/.aws/credentials

# 3. Verificar acceso
aws sts get-caller-identity

# 4. Configurar variables de entorno
echo 'export AWS_ACCESS_KEY_ID="..."' >> ~/.bashrc
source ~/.bashrc

# 5. Crear terraform.tfvars
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Editar con tus valores
```

### 2️⃣ Fase GitHub

```bash
# 1. Crear GitHub Personal Token
# (en GitHub: Settings → Developer settings)

# 2. Configurar secretos en GitHub
gh secret set AWS_ACCESS_KEY_ID -b "AKIA..."
gh secret set AWS_SECRET_ACCESS_KEY -b "wJal..."
gh secret set GH_TOKEN_AMPLIFY -b "ghp_..."

# 3. Verificar
gh secret list
```

### 3️⃣ Fase Pre-deploy Checks

```bash
# 1. Verificaciones locales
make check

# 2. Tests
make test

# 3. Terraform validation
make tf-validate

# 4. Ver plan
make tf-plan
```

### 4️⃣ Fase Deployment

```bash
# 1. Desplegar infraestructura
cd terraform
terraform init
terraform apply -var="github_token=YOUR_TOKEN"

# 2. Anotar outputs
terraform output -json > outputs.json

# 3. Actualizar endpoint API en frontend
# Copiar el API endpoint de los outputs
# Editar curriculum/scripts/visitor-counter.js
# Reemplazar: const API_ENDPOINT = "..."

# 4. Commit y push a main
git add .
git commit -m "feat: Deploy infrastructure"
git push origin main

# 5. Monitorear workflows
gh run list
```

### 5️⃣ Post-deployment Verification

```bash
# 1. Verificar Lambda
make aws-status

# 2. Probar endpoint
curl https://cv.aws10.atercates.cat

# 3. Ver logs
make lambda-logs

# 4. Invocar función
make lambda-invoke
```

---

## 🔒 Seguridad - Best Practices

### Nunca hacer commit:

```
❌ terraform/terraform.tfvars (con tokens reales)
❌ AWS credentials en variables.tf
❌ .env.local
❌ *.pem keys
❌ GitHub tokens en plaintext
```

### Usar valores seguros:

```bash
# ✅ Usar variables de entorno
terraform apply -var="github_token=$TF_VAR_github_token"

# ✅ Usar archivos de variables sin commit
terraform apply -var-file="terraform.tfvars"
# (terraform.tfvars está en .gitignore)

# ✅ Usar secretos de GitHub
# No pasar credenciales por GitHub Actions
```

### Rotar credenciales regularmente:

```bash
# Cada 90 días, generar nuevas Access Keys
# 1. Crear nueva Access Key en IAM
# 2. Actualizar en ~/.aws/credentials
# 3. Actualizar en GitHub Secrets
# 4. Eliminar Access Key antigua
```

---

## 📞 Resumen de Variables por Ubicación

| Ubicación | Variable | Valor | Donde obtener |
|-----------|----------|-------|---------------|
| **~/.aws/credentials** | aws_access_key_id | AKIA... | AWS IAM Console |
| **~/.aws/credentials** | aws_secret_access_key | wJal... | AWS IAM Console |
| **~/.bashrc** | AWS_ACCESS_KEY_ID | AKIA... | AWS IAM Console |
| **~/.bashrc** | AWS_SECRET_ACCESS_KEY | wJal... | AWS IAM Console |
| **~/.bashrc** | AWS_REGION | eu-west-1 | Elegir región |
| **terraform.tfvars** | github_token | ghp_... | GitHub Settings |
| **terraform.tfvars** | domain_name | cv.aws10.atercates.cat | Elegir subdominio |
| **GitHub Secrets** | AWS_ACCESS_KEY_ID | AKIA... | AWS IAM Console |
| **GitHub Secrets** | AWS_SECRET_ACCESS_KEY | wJal... | AWS IAM Console |
| **GitHub Secrets** | GH_TOKEN_AMPLIFY | ghp_... | GitHub Settings |
| **Cloudflare** | API_TOKEN | cf_... | Cloudflare Console (opcional) |

---

**Última actualización:** 8 de enero de 2026

**Próximo paso:** Una vez configurado todo, ejecuta `make check` para verificar que todo esté listo.
