# 🔐 Configuración de Secretos en GitHub Actions

## 📋 Resumen Completo

Para que las pipelines de CI/CD funcionen correctamente, necesitas configurar **3 secretos** en GitHub Actions:

---

## 🚀 Secretos Requeridos en GitHub

### Ubicación: Settings → Secrets and variables → Actions

| Secreto | Descripción | Valor Ejemplo | Requisito |
|---------|-------------|---------------|-----------|
| **AWS_ACCESS_KEY_ID** | Access Key de AWS IAM User | `AKIA2BXNZ3A7EXAMPLE` | ✅ **OBLIGATORIO** |
| **AWS_SECRET_ACCESS_KEY** | Secret Key de AWS IAM User | `wJalrXUtnFEMI/K7MDENGbPxRfCHEXAMPLEKEY` | ✅ **OBLIGATORIO** |
| **GH_TOKEN_AMPLIFY** | GitHub Personal Access Token | `ghp_5g6h7j8k9l0m1n2o3p4q5r6s7t8u9v0w` | ✅ **OBLIGATORIO** |

---

## 🔑 Paso 1: Crear Credenciales AWS

### 1.1 Crear IAM User en AWS Console

1. Ve a **AWS Console** → **IAM** → **Users** → **Create user**
2. Nombre: `cloud-cv-deployer`
3. Click **Next**

### 1.2 Asignar Permisos

Adjunta estas políticas al usuario (las puedes asignar directamente):
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

O usa esta política mínima (JSON):

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
        "s3:*",
        "cloudfront:*",
        "ec2:*VPC*"
      ],
      "Resource": "*"
    }
  ]
}
```

### 1.3 Crear Access Keys

1. Click en el usuario `cloud-cv-deployer`
2. Ve a **Security credentials** → **Create access key**
3. Selecciona: **Command Line Interface (CLI)**
4. Click **Create access key**
5. **COPIAR:**
   - `Access Key ID` → Este es tu `AWS_ACCESS_KEY_ID`
   - `Secret Access Key` → Este es tu `AWS_SECRET_ACCESS_KEY`

⚠️ **IMPORTANTE:** Descarga el CSV, no podrás ver el Secret Key de nuevo

---

## 🐙 Paso 2: Crear GitHub Personal Access Token

### 2.1 Crear el Token

1. Ve a **GitHub** → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. Click **Generate new token (classic)**
3. **Token name:** `Cloud CV Amplify Token`
4. **Expiration:** 90 days (recomendado) o Never (más riesgoso)
5. **Scopes (selectiona):**
   - ✅ `repo` (Full control of private repositories)
   - ✅ `user:email` (Access user email addresses)
6. Click **Generate token**
7. **COPIAR el token inmediatamente** → Este es tu `GH_TOKEN_AMPLIFY`

⚠️ **IMPORTANTE:** Solo aparece una vez, guárdalo en lugar seguro

---

## 📝 Paso 3: Agregar Secretos a GitHub

### 3.1 Vía GitHub Web UI

1. Ve a **tu repositorio** → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Rellena **Name:** `AWS_ACCESS_KEY_ID`
4. Rellena **Secret:** tu Access Key (`AKIA...`)
5. Click **Add secret**

**Repite el proceso para los otros dos secretos:**
- `AWS_SECRET_ACCESS_KEY` con tu Secret Key
- `GH_TOKEN_AMPLIFY` con tu GitHub Token

### 3.2 Vía GitHub CLI

```bash
# Instalar GitHub CLI si no lo tienes
brew install gh  # macOS
# O en Linux: https://github.com/cli/cli/blob/trunk/docs/install_linux.md

# Autenticarse
gh auth login

# Agregar secretos
gh secret set AWS_ACCESS_KEY_ID -b "AKIA2BXNZ3A7EXAMPLE"
gh secret set AWS_SECRET_ACCESS_KEY -b "wJalrXUtnFEMI/K7MDENGbPxRfCHEXAMPLEKEY"
gh secret set GH_TOKEN_AMPLIFY -b "ghp_5g6h7j8k9l0m1n2o3p4q5r6s7t8u9v0w"

# Verificar secretos
gh secret list
```

---

## 🌍 Configuración de Región en Workflows

Los workflows usan la región **`us-east-1`** configurada en las variables de entorno:

| Workflow | Región | Ubicación |
|----------|--------|-----------|
| `frontend-deploy.yml` | `us-east-1` | Line 18: `AWS_REGION: us-east-1` |
| `backend-deploy.yml` | `us-east-1` | Line 23: `AWS_REGION: us-east-1` |
| `terraform-deploy.yml` | `us-east-1` | Line 32: `AWS_REGION: us-east-1` |

Este debe coincidir con tu `terraform/terraform.tfvars`:
```terraform
aws_region = "us-east-1"
```

---

## ✅ Verificar Configuración

### 3.1 Verificar Credenciales AWS Localmente

```bash
# Guardar en ~/.aws/credentials
aws configure

# O manual:
cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = AKIA2BXNZ3A7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENGbPxRfCHEXAMPLEKEY
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

### 3.2 Verificar Secretos en GitHub

```bash
# Listar secretos
gh secret list

# Salida esperada:
# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# GH_TOKEN_AMPLIFY
```

### 3.3 Verificar Variables de Entorno Locales

Para desarrollo local, también puedes configurar:

```bash
# Agregar a ~/.bashrc o ~/.zshrc
export AWS_ACCESS_KEY_ID="AKIA2BXNZ3A7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENGbPxRfCHEXAMPLEKEY"
export AWS_REGION="us-east-1"
export TF_VAR_github_token="ghp_5g6h7j8k9l0m1n2o3p4q5r6s7t8u9v0w"
```

O crear `.env.local` (no commitear):

```bash
AWS_ACCESS_KEY_ID=AKIA2BXNZ3A7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENGbPxRfCHEXAMPLEKEY
AWS_REGION=us-east-1
TF_VAR_github_token=ghp_5g6h7j8k9l0m1n2o3p4q5r6s7t8u9v0w
```

Luego: `source .env.local`

---

## 🚀 Cómo Funcionan las Pipelines

### Frontend Deploy
**Trigger:** Push a `main` en `/curriculum/**`
**Secretos usados:** `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
**Acción:** Despliega sitio estático en Amplify

### Backend Deploy
**Trigger:** Push a `main` en `/lambda/**` o PR en `/lambda/**`
**Secretos usados:** `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
**Acciones:**
1. Ejecuta tests con `pytest`
2. Sube reporte de cobertura
3. Empaqueta Lambda (solo en `main`)
4. Despliega a AWS Lambda

### Terraform Deploy
**Trigger:** Push a `main` en `/terraform/**` o PR en `/terraform/**`
**Secretos usados:** Todos (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `GH_TOKEN_AMPLIFY`)
**Acciones:**
1. Valida formato Terraform
2. Genera plan de cambios
3. Aplica cambios (solo en `main`)

---

## 🔒 Buenas Prácticas de Seguridad

✅ **HACER:**
- Usar secretos para información sensible
- Rotar credenciales periódicamente
- Limitar permisos IAM al mínimo necesario
- Usar GitHub tokens con expiration date

❌ **NO HACER:**
- Commitear secretos en el repositorio
- Compartir credenciales por chat/email
- Usar el mismo token en múltiples proyectos
- Guardar secretos en archivos locales sin `.gitignore`

---

## 📞 Troubleshooting

### Error: "Invalid credentials"
- Verifica que el Access Key y Secret Key sean correctos
- Asegúrate de que el usuario tenga los permisos necesarios
- Regenera las credenciales si olvidaste el Secret Key

### Error: "Unauthorized to perform: amplify:..."
- El usuario IAM no tiene permisos para Amplify
- Agrega la política `AWSAmplifyFullAccess`

### Error: "github_token not specified"
- El secreto `GH_TOKEN_AMPLIFY` no está configurado
- Crea un GitHub Personal Access Token nuevo
- Asegúrate de que `repo` scope esté seleccionado

---

## 📋 Checklist de Configuración

- [ ] IAM User creado (`cloud-cv-deployer`)
- [ ] Access Key ID copiado
- [ ] Secret Access Key copiado y guardado
- [ ] GitHub Personal Token creado
- [ ] Secreto `AWS_ACCESS_KEY_ID` agregado a GitHub
- [ ] Secreto `AWS_SECRET_ACCESS_KEY` agregado a GitHub
- [ ] Secreto `GH_TOKEN_AMPLIFY` agregado a GitHub
- [ ] Región `us-east-1` en `terraform/terraform.tfvars`
- [ ] Región `us-east-1` en todos los workflows
- [ ] Credenciales locales en `~/.aws/credentials`
- [ ] Variables de entorno locales configuradas

---

✅ **Una vez completado este checklist, tus pipelines están listas para funcionar.**
