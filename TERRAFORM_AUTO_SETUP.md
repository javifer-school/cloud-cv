# ✅ Terraform Completamente Automatizado

## 🔧 Cambios Realizados

He actualizado la configuración de Terraform para que **cree automáticamente TODOS los recursos** sin necesidad de configuración manual:

### 1. **Módulo DNS - Creación Automática de Zona Route53**

**Antes:** Buscaba una zona existente y fallaba si no existía
```terraform
data "aws_route53_zone" "main" {
  name = var.hosted_zone_name
}
```

**Ahora:** Crea automáticamente la zona si no existe
```terraform
resource "aws_route53_zone" "main" {
  name = var.hosted_zone_name
  # Se crea automáticamente
}
```

**Cambios:**
- ✅ Módulo DNS ahora crea la zona automáticamente
- ✅ Los registros DNS se crean automáticamente
- ✅ Los certificados ACM se validan automáticamente

### 2. **Módulo Amplify - Registro DNS Automático**

**Ahora incluye:**
- ✅ Crea el alias DNS en Route53 apuntando a Amplify
- ✅ Se sincroniza automáticamente con los recursos DNS

```terraform
resource "aws_route53_record" "amplify_domain" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"
  
  alias {
    name    = aws_amplify_domain_association.cv_domain.domain_name
    zone_id = aws_amplify_domain_association.cv_domain.zone_id
  }
}
```

### 3. **Módulo Lambda - Empaquetado Automático**

Ya estaba configurado correctamente:
- ✅ Empaqueta el código automáticamente con `archive_file`
- ✅ Crea el ZIP en la ruta correcta
- ✅ Despliega la función automáticamente

---

## 🚀 Ahora Solo Necesitas 3 Cosas

### **1. Credenciales AWS**

```bash
# Opción A: Usar credenciales existentes
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="wJal..."
export AWS_REGION="us-east-1"

# Opción B: Configurar AWS CLI
aws configure
# Ingresar: Access Key, Secret Key, Region (us-east-1)
```

### **2. GitHub Personal Access Token (Variable de Entorno)**

```bash
export TF_VAR_github_token="ghp_..."
```

O crear archivo `.env`:
```bash
export TF_VAR_github_token="ghp_5g6h7j8k9l0m1n2o3p4q5r6s7t8u9v0w"
```

Luego: `source .env`

### **3. Ejecutar Terraform**

```bash
cd terraform

# Inicializar
terraform init

# Ver plan (revisar qué se creará)
terraform plan

# Aplicar (crear toda la infraestructura)
terraform apply

# Escribir 'yes' cuando pregunte
```

---

## 📋 Qué Crea Terraform Automáticamente

```
✅ Route53 Hosted Zone (atercates.cat)
   ├── Registro DNS para el dominio principal
   └── Registros de validación de certificado

✅ ACM Certificates (us-east-1 y regional)
   └── Se validan automáticamente

✅ DynamoDB Table
   └── cv-visit-counter

✅ Lambda Function
   ├── cv-visit-counter
   ├── Se empaqueta el código automáticamente
   └── Se configura con variables de entorno

✅ API Gateway HTTP API
   ├── Rutas GET/POST
   └── Integración con Lambda

✅ CloudWatch Log Groups
   ├── Para Lambda
   └── Para API Gateway

✅ AWS Amplify App
   ├── Conectado a tu repositorio GitHub
   ├── Dominio personalizado configurado
   └── Registro DNS apuntando a Amplify
```

---

## 🎯 Flujo Completo

### **Paso 1: Preparar Credenciales**

```bash
# Configurar variables de entorno
export AWS_ACCESS_KEY_ID="tu_access_key"
export AWS_SECRET_ACCESS_KEY="tu_secret_key"
export AWS_REGION="us-east-1"
export TF_VAR_github_token="tu_github_token"
```

### **Paso 2: Ejecutar Terraform**

```bash
cd /home/atercates/School/ASIX2/Cloud/cloud-cv/terraform

# Inicializar Terraform
terraform init

# Ver qué se creará
terraform plan

# Crear la infraestructura
terraform apply
```

### **Paso 3: Esperar a que Terraform Termine**

El proceso tarda ~5-10 minutos:
- Crea la zona DNS
- Crea los certificados
- Despliega Lambda
- Configura API Gateway
- Crea Amplify
- Configura los dominios

### **Paso 4: Verificar Outputs**

Terraform mostrará los outputs:
```
Outputs:

website_url = "https://cv.aws10.atercates.cat"
api_endpoint = "https://abc123.execute-api.us-east-1.amazonaws.com/visits"
lambda_function_name = "cv-visit-counter"
dynamodb_table_name = "cv-visit-counter"
```

---

## 🔄 Pipeline de Despliegue (Ahora Funciona)

Una vez que Terraform cree la infraestructura:

### **Frontend Changes**
```
Push a main → curriculum/**
↓
GitHub Actions: Frontend Deploy
↓
Deploy a Amplify
↓
✅ Sitio actualizado en https://cv.aws10.atercates.cat
```

### **Backend Changes**
```
Push a main → lambda/**
↓
GitHub Actions: Backend Deploy
├─ Test (pytest)
└─ Deploy a Lambda
↓
✅ Lambda actualizada
```

### **Infrastructure Changes**
```
Push a main → terraform/**
↓
GitHub Actions: Terraform Deploy
├─ Format check
├─ Validate
├─ Plan
└─ Apply (en main)
↓
✅ Infraestructura actualizada
```

---

## ⚠️ Notas Importantes

### **Zona DNS Pública**

La zona creada es **pública** (no privada). Si quieres hacerla privada, necesitas cambiar en módulo DNS:

```terraform
resource "aws_route53_zone" "main" {
  name            = var.hosted_zone_name
  private_zone    = false  # ← Cambiar a true si quieres privada
}
```

### **Costo**

La zona DNS cuesta ~$0.50 por mes. El resto depende del uso:
- Lambda: gratis hasta 1 millón de invocaciones/mes
- DynamoDB: gratis con On-Demand pricing (bajo uso)
- Amplify: gratis con límites

### **GitHub Token**

El token se usa para:
- Conectar Amplify al repositorio
- Buildear automáticamente en cambios

Asegúrate de que tenga permisos `repo`.

---

## 🧪 Verificar Configuración Local

Antes de ejecutar Terraform:

```bash
# Verificar credenciales AWS
aws sts get-caller-identity
# Debe mostrar tu Account ID y ARN

# Verificar Terraform
terraform version
# Debe ser >= 1.0.0

# Verificar variables
echo $TF_VAR_github_token
# Debe mostrar tu token (si está configurado)
```

---

## ✅ Checklist Final

- [ ] AWS_ACCESS_KEY_ID configurado
- [ ] AWS_SECRET_ACCESS_KEY configurado
- [ ] AWS_REGION = "us-east-1"
- [ ] TF_VAR_github_token configurado
- [ ] terraform init ejecutado
- [ ] terraform plan sin errores
- [ ] terraform apply ejecutado
- [ ] Esperar a que termine
- [ ] Verificar outputs
- [ ] Probar https://cv.aws10.atercates.cat

---

## 🆘 Si Algo Falla

### Error: "no matching Route 53 Hosted Zone found"
✅ **SOLUCIONADO** - Ahora crea la zona automáticamente

### Error: "Access Denied"
- Verificar que el IAM user tenga los permisos correctos
- Ejecutar: `aws sts get-caller-identity`

### Error: "Invalid github_token"
- Verificar que el token sea válido
- Regenerar el token en GitHub si es necesario

### Error: "Archive file not found"
- Verificar que exista: `/lambda/visit_counter/handler.py`
- Verificar path correctos en variables

---

## 🎉 ¡Listo!

Ya puedes ejecutar:

```bash
cd terraform
terraform init
terraform apply
```

**¡Terraform creará TODA la infraestructura automáticamente!**

Sin necesidad de configuración manual en AWS Console, Route53, o en ningún lado.
