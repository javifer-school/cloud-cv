# 🔐 Configuración de Cloudflare con Terraform

## 📋 Resumen

Si quieres usar **Cloudflare como DNS** (en lugar de Route53), Terraform ahora soporta ambas opciones automáticamente:

- **Si configuras `cloudflare_api_token`:** Usará Cloudflare para validar los certificados ACM
- **Si no lo configuras:** Usará Route53 (comportamiento anterior)

---

## 🚀 Pasos para Configurar Cloudflare

### 1. Obtener API Token de Cloudflare

**En Cloudflare Dashboard:**

1. Ve a **Mi Perfil → Tokens de API**
2. Click **Crear Token**
3. Selecciona **Editar registros DNS de zona**
4. Configura los permisos:
   - ✅ **Zone.DNS** - Edit
   - ✅ **Zone.Zone Settings** - Read
5. Selecciona la zona: **atercates.cat**
6. Click **Continuar a resumen**
7. Click **Crear Token**
8. **Copia el token inmediatamente** (solo aparece una vez)

### 2. Configurar en Terraform

**Opción A: Mediante variables de entorno (RECOMENDADO)**

```bash
# En tu ~/.bashrc o ~/.zshrc
export TF_VAR_cloudflare_api_token="xxxxxxxxxxxxxxxxxxx"
export TF_VAR_cloudflare_zone_id="xxxxxxxxxxxxx"

# Recargar shell
source ~/.bashrc  # o ~/.zshrc
```

**Opción B: Mediante terraform.tfvars**

```bash
# Editar terraform/terraform.tfvars
cloudflare_api_token = "xxxxxxxxxxxxxxxxxxx"
cloudflare_zone_id   = "xxxxxxxxxxxxx"

# ⚠️ IMPORTANTE: Agregar a .gitignore
echo "terraform.tfvars" >> .gitignore
```

**Opción C: Mediante flag en command line**

```bash
terraform plan \
  -var="cloudflare_api_token=xxxxxxxxxxxxxxxxxxx" \
  -var="cloudflare_zone_id=xxxxxxxxxxxxx"
```

### 3. Verificar Token

```bash
# Con curl
curl -X GET "https://api.cloudflare.com/client/v4/user" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json"

# Respuesta esperada:
# {
#   "success": true,
#   "result": {...},
#   ...
# }
```

### 4. Ejecutar Terraform

```bash
# En terraform/
cd terraform

# Ver el plan
terraform plan

# Aplicar cambios
terraform apply
```

**Automáticamente hará:**

✅ Validar certificados ACM mediante Cloudflare (no Route53)  
✅ Crear registros CNAME en Cloudflare para Amplify  
✅ Configurar HTTPS con certificados validados  
✅ **SIN crear hosted zone en Route53**

---

## 🔄 Migrar de Route53 a Cloudflare

Si ya tienes recursos en Route53 y quieres cambiar a Cloudflare:

### 1. Destruir recursos actuales

```bash
cd terraform

# Ver qué se va a destruir (IMPORTANTE!)
terraform plan -destroy

# Destruir
terraform destroy
```

### 2. Configurar Cloudflare

```bash
export TF_VAR_cloudflare_api_token="tu_token"
export TF_VAR_cloudflare_zone_id="tu_zone_id"
```

### 3. Redeploy

```bash
terraform init
terraform plan
terraform apply
```

---

## 📊 Comparación: Cloudflare vs Route53

| Aspecto | Cloudflare | Route53 |
|---------|-----------|---------|
| **Costo** | Gratis (básico) | ~0.50$/mes por hosted zone |
| **Validación DNS** | Automática en esta config | Manual (nameservers) |
| **CDN** | Incluido | Separado (CloudFront) |
| **Gestión de DNS** | Interfaz simple | Interfaz AWS |
| **Propagación** | Rápida (< 1m) | Media (hasta 24h) |

---

## ⚙️ Configuración en terraform.tfvars

Después de `terraform init`, edita `terraform/terraform.tfvars`:

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
github_token      = "ghp_..."

# DynamoDB
dynamodb_table_name = "cv-visit-counter"

# Lambda
lambda_function_name = "cv-visit-counter"
lambda_runtime       = "python3.11"
lambda_memory        = 128
lambda_timeout       = 10

# ⭐ Cloudflare (NUEVO)
cloudflare_api_token = "tu_token_aqui"
cloudflare_zone_id   = "tu_zone_id_aqui"
```

---

## 🐛 Troubleshooting

### "Error: Unsupported argument 'providers'"

```
Error: Unsupported argument
  on .../modules/dns/main.tf line X:
    providers = {...}
```

**Solución:**
```bash
cd terraform
terraform init -upgrade
```

### "Error: API call failed (invalid credentials)"

```
Error: Error making API request: 
  invalid token or bad authentication
```

**Soluciones:**
1. Verifica que el token sea correcto
2. Copia el token COMPLETO (sin espacios)
3. Usa comillas en bash si el token tiene caracteres especiales

```bash
export TF_VAR_cloudflare_api_token='xxxxxxxxxxxxxxxxxxx'
```

### "Timeout waiting for certificate validation"

Si Terraform se queda esperando > 10 minutos:

1. **Verifica que el token sea válido**
   ```bash
   curl -X GET "https://api.cloudflare.com/client/v4/user" \
     -H "Authorization: Bearer $TF_VAR_cloudflare_api_token"
   ```

2. **Verifica que la zona existe en Cloudflare**
   ```bash
   curl -X GET "https://api.cloudflare.com/client/v4/zones" \
     -H "Authorization: Bearer $TF_VAR_cloudflare_api_token"
   ```

3. **Si nada funciona, usa Route53 (fallback)**
   ```bash
   # Sin configurar cloudflare_api_token
   terraform plan
   ```

---

## ✅ Verificación Final

Después de `terraform apply`:

```bash
# Ver recursos creados
terraform show

# Verificar certificado
aws acm describe-certificate \
  --certificate-arn $(terraform output -raw certificate_arn) \
  --region us-east-1

# Verificar registros en Cloudflare
curl -X GET "https://api.cloudflare.com/client/v4/zones/ZONE_ID/dns_records" \
  -H "Authorization: Bearer $TF_VAR_cloudflare_api_token" | jq .

# Verificar HTTPS funciona
curl -I https://cv.aws10.atercates.cat
```

---

## 📝 Variables de Entorno para GitHub Actions

Si quieres que GitHub Actions también use Cloudflare:

**Settings → Secrets and variables → Actions**

Añade:
- `CLOUDFLARE_API_TOKEN` - Tu token
- `CLOUDFLARE_ZONE_ID` - Tu zone ID (opcional)

---

**¿Preguntas?** Revisa la documentación oficial:
- [Cloudflare API Docs](https://developers.cloudflare.com/api/)
- [Terraform Cloudflare Provider](https://registry.terraform.io/providers/cloudflare/cloudflare/latest)
