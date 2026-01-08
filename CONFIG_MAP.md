# 🗺️ Mapa de Configuración - Cloud CV

## 📊 Variables por Ubicación

```
┌─────────────────────────────────────────────────────────────────┐
│                   TU MÁQUINA LOCAL                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ~/.aws/credentials              ~/.bashrc / ~/.zshrc           │
│  ┌──────────────────────┐       ┌────────────────────────────┐ │
│  │ [default]            │       │ export AWS_REGION          │ │
│  │ aws_access_key_id    │◄──────│   eu-west-1                │ │
│  │   = AKIA...          │       │ export AWS_ACCESS_KEY_ID   │ │
│  │ aws_secret_access_key│◄──────│   = AKIA...                │ │
│  │   = wJal...          │       │ export TF_VAR_github_token │ │
│  └──────────────────────┘       │   = ghp_...                │ │
│                                 └────────────────────────────┘ │
│                                                                 │
│  terraform/terraform.tfvars                                    │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ aws_region              = "eu-west-1"                   │  │
│  │ github_token            = "ghp_..."                     │  │
│  │ domain_name             = "cv.aws10.atercates.cat"      │  │
│  │ hosted_zone_name        = "atercates.cat"               │  │
│  │ github_repository       = "https://github.com/..."      │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      GITHUB REPOSITORY                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Settings → Secrets and variables → Actions                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ AWS_ACCESS_KEY_ID          = AKIA...                    │  │
│  │ AWS_SECRET_ACCESS_KEY      = wJal...                    │  │
│  │ GH_TOKEN_AMPLIFY           = ghp_...                    │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  .github/workflows/*.yml (CI/CD Pipelines)                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ ✓ frontend-deploy.yml                                   │  │
│  │ ✓ backend-deploy.yml      (con tests)                   │  │
│  │ ✓ terraform-deploy.yml    (plan + apply)                │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        AWS ACCOUNT                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  IAM User: cloud-cv-deployer                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Access Key ID        = AKIA...                           │  │
│  │ Secret Access Key    = wJal...                           │  │
│  │ Permissions:                                             │  │
│  │   - Lambda (full)                                        │  │
│  │   - DynamoDB (full)                                      │  │
│  │   - Amplify (full)                                       │  │
│  │   - Route53 (full)                                       │  │
│  │   - ACM (full)                                           │  │
│  │   - IAM (create roles)                                   │  │
│  │   - CloudWatch (full)                                    │  │
│  │   - API Gateway (full)                                   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  Route53: Hosted Zone                                          │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Domain: atercates.cat                                    │  │
│  │ Zone ID: /hostedzone/Z1234ABCD                           │  │
│  │ Nameservers: ns-123.awsdns-45.com, ...                  │  │
│  │              (actualizar en registrador)                 │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  S3 Bucket (Terraform Backend) - OPCIONAL                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Name: cloud-cv-terraform-state-xxx                       │  │
│  │ - Versionado: habilitado                                 │  │
│  │ - Encriptación: AES256                                   │  │
│  │ - Acceso público: bloqueado                              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CLOUDFLARE (OPCIONAL)                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  API Token                                                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Token: cf_...                                            │  │
│  │ Permissions:                                             │  │
│  │   - Zone.DNS (Edit)                                      │  │
│  │   - Zone.Zone Settings (Read)                            │  │
│  │ Zones: atercates.cat                                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## ⚙️ Flujo de Configuración

```
1. CREAR CREDENCIALES AWS
   │
   ├─→ IAM User: cloud-cv-deployer
   │   ├─→ Generate Access Key
   │   ├─→ Asignar Permisos
   │   └─→ Guardar credenciales
   │
   └─→ Verified con: aws sts get-caller-identity ✓

2. CONFIGURAR LOCALLY
   │
   ├─→ ~/.aws/credentials (Access Key + Secret Key)
   ├─→ ~/.bashrc (variables de entorno)
   ├─→ terraform/terraform.tfvars (variables Terraform)
   └─→ Verified con: make check ✓

3. CREAR GITHUB TOKEN
   │
   ├─→ GitHub: Settings → Personal access tokens
   ├─→ Scope: repo (full control)
   └─→ Guardar token

4. CONFIGURAR GITHUB SECRETS
   │
   ├─→ AWS_ACCESS_KEY_ID
   ├─→ AWS_SECRET_ACCESS_KEY
   └─→ GH_TOKEN_AMPLIFY
   └─→ Verified con: gh secret list ✓

5. PREPARAR AWS (ONCE)
   │
   ├─→ Route53: Verify hosted zone atercates.cat
   ├─→ S3: Create bucket para Terraform state (opcional)
   └─→ DynamoDB: Create locks table (opcional)

6. DESPLEGAR
   │
   ├─→ Local: terraform init
   ├─→ Local: terraform plan
   ├─→ Local: terraform apply
   ├─→ GitHub: Push a main (activa CI/CD)
   └─→ Verify con: make aws-status ✓
```

---

## 📋 Checklist Rápido

### Credenciales AWS
- [ ] IAM User creado: `cloud-cv-deployer`
- [ ] Access Key: `AKIA...` (anotado)
- [ ] Secret Key: `wJal...` (guardado seguro)
- [ ] Permisos: Lambda, DynamoDB, Amplify, Route53, ACM, IAM

### Configuración Local
- [ ] `~/.aws/credentials` actualizado
- [ ] `~/.bashrc` tiene variables AWS
- [ ] `terraform/terraform.tfvars` creado
- [ ] `terraform/terraform.tfvars` NO está en Git
- [ ] Verificado: `aws sts get-caller-identity`

### GitHub
- [ ] Personal Access Token creado
- [ ] Secreto `AWS_ACCESS_KEY_ID` añadido
- [ ] Secreto `AWS_SECRET_ACCESS_KEY` añadido
- [ ] Secreto `GH_TOKEN_AMPLIFY` añadido
- [ ] Verificado: `gh secret list`

### AWS Preparativos
- [ ] Hosted Zone `atercates.cat` en Route53
- [ ] Nameservers actualizado en registrador (si es necesario)
- [ ] S3 bucket para state (opcional pero recomendado)
- [ ] DynamoDB locks table (opcional pero recomendado)

### Pre-Deploy Final
- [ ] `make check` pasa ✓
- [ ] `make test` pasa ✓
- [ ] `make tf-validate` pasa ✓
- [ ] `make tf-plan` sin errores ✓

---

## 🔑 Variables Mínimas Requeridas

### Absolutamente necesarias:

```
AWS_ACCESS_KEY_ID           (AWS IAM)
AWS_SECRET_ACCESS_KEY       (AWS IAM)
TF_VAR_github_token         (GitHub)
AWS_REGION                  (Default: eu-west-1)
```

### Recomendadas:

```
TF_VAR_domain_name          (Default: cv.aws10.atercates.cat)
TF_VAR_hosted_zone_name     (Default: atercates.cat)
AWS_ACCOUNT_ID              (Para logs y referencias)
```

### Opcionales:

```
CLOUDFLARE_API_TOKEN        (Si usas Cloudflare como DNS)
CF_API_TOKEN                (Alias para Cloudflare)
TF_LOG                      (Debug: DEBUG, TRACE)
TF_LOG_PATH                 (Guardar logs a archivo)
```

---

## 🚨 Errores Comunes

### "Access Denied" al hacer `terraform plan`

```
Causa: Credenciales AWS incorrectas o sin permisos
Solución:
1. Verificar: aws sts get-caller-identity
2. Verificar permisos en IAM User
3. Regenerar Access Keys si es necesario
```

### "terraform.tfvars: resource not found"

```
Causa: Variables no configuradas
Solución:
1. Crear: cp terraform/terraform.tfvars.example terraform/terraform.tfvars
2. Editar con tus valores
3. Verificar: terraform validate
```

### "github_token is required"

```
Causa: Token de GitHub no configurado
Solución:
1. Generar token: GitHub → Settings → Personal access tokens
2. Configurar: terraform apply -var="github_token=ghp_..."
3. O en terraform.tfvars: github_token = "ghp_..."
```

### "Hosted zone not found"

```
Causa: Dominio no existe en Route53
Solución:
1. Crear zona: aws route53 create-hosted-zone --name atercates.cat --caller-reference $(date +%s)
2. Actualizar nameservers en registrador
3. Esperar propagación DNS (puede tardar 24h)
```

---

**Última actualización:** 8 de enero de 2026

**Próximo paso:** Abre [SETUP_GUIDE.md](SETUP_GUIDE.md) para detalles completos
