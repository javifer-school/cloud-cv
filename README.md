# Cloud CV - AWS Cloud Resume Challenge

[![Terraform Deploy](https://github.com/javifer-school/cloud-cv/actions/workflows/terraform-deploy.yml/badge.svg)](https://github.com/javifer-school/cloud-cv/actions/workflows/terraform-deploy.yml)
[![Lambda Tests](https://github.com/javifer-school/cloud-cv/actions/workflows/lambda-tests.yml/badge.svg)](https://github.com/javifer-school/cloud-cv/actions/workflows/lambda-tests.yml)

> **Implementación profesional del Cloud Resume Challenge usando AWS, Terraform y CI/CD**

🌐 **Live Demo**: [https://cv.aws10.atercates.cat](https://cv.aws10.atercates.cat)

---

## 📋 Índice

- [Descripción](#-descripción)
- [Arquitectura](#️-arquitectura)
- [Tecnologías](#️-tecnologías)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Quick Start](#-quick-start)
- [Configuración Detallada](#️-configuración-detallada)
- [CI/CD Pipelines](#-cicd-pipelines)
- [Testing](#-testing)
- [API Reference](#-api-reference)
- [Troubleshooting](#-troubleshooting)

---

## 📖 Descripción

Este proyecto implementa el [Cloud Resume Challenge](https://cloudresumechallenge.dev/docs/the-challenge/aws/) utilizando las mejores prácticas de DevOps y Cloud Engineering. Es un curriculum vitae interactivo desplegado en AWS con las siguientes características:

### ✨ Características Principales

- 🌐 **Static Website Hosting**: AWS Amplify con integración continua desde GitHub
- 👁️ **Visitor Counter**: Contador de visitas serverless con Lambda + DynamoDB
- 🔒 **HTTPS Custom Domain**: Certificado SSL/TLS con ACM y DNS en Cloudflare
- 🚀 **Infrastructure as Code**: Todo gestionado con Terraform (modular y reutilizable)
- 🔄 **CI/CD Completo**: GitHub Actions para tests, validación y deployment automático
- 📊 **Testing**: Suite completa de tests unitarios con >90% coverage
- 🔐 **Seguridad**: CORS configurado, credenciales en secretos, backend state en S3

### 🎯 Objetivos del Proyecto

1. Demostrar competencia en arquitecturas serverless en AWS
2. Implementar IaC con Terraform siguiendo mejores prácticas
3. Configurar CI/CD pipelines profesionales
4. Aplicar principios de testing y code quality
5. Gestionar DNS y certificados SSL/TLS
6. Documentar de forma clara y completa

---

## 🏗️ Arquitectura

### Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────────────┐
│                          GitHub Repository                          │
│                    (Source Code + CI/CD Triggers)                   │
└───────────────┬──────────────────────────┬──────────────────────────┘
                │                          │
                ▼                          ▼
        ┌───────────────┐          ┌──────────────┐
        │ GitHub Actions│          │    Terraform │
        │   (CI/CD)     │          │    (IaC)     │
        └───────┬───────┘          └──────┬───────┘
                │                          │
                │                          ▼
                │              ┌──────────────────────┐
                │              │   S3 Backend         │
                │              │ (Terraform State)    │
                │              └──────────────────────┘
                │
                ▼
    ┌──────────────────────┐
    │   AWS Amplify        │
    │ (Static Hosting +    │
    │  Auto Build)         │
    └──────┬───────────────┘
           │
           │ HTTPS (ACM Cert)
           ▼
    ┌──────────────────────┐           ┌─────────────────┐
    │   Cloudflare DNS     │◀──────────│  Custom Domain  │
    │  (cv.aws10...)       │           │   (CNAME)       │
    └──────────────────────┘           └─────────────────┘

           │
           │ User visits website
           ▼
    ┌──────────────────────┐
    │   Frontend           │
    │  (HTML/CSS/JS)       │
    └──────┬───────────────┘
           │
           │ API Request (fetch)
           ▼
    ┌──────────────────────┐
    │  API Gateway         │
    │  (HTTP API)          │
    └──────┬───────────────┘
           │
           ▼
    ┌──────────────────────┐         ┌──────────────────┐
    │   AWS Lambda         │────────▶│   DynamoDB       │
    │ (Visit Counter)      │         │ (Visit Records)  │
    │  - Python 3.11       │◀────────│  - visitor_ip    │
    │  - CORS enabled      │         │  - total_visits  │
    └──────────────────────┘         │  - timestamps    │
                                     └──────────────────┘
```

### Flujo de Datos

1. **Usuario accede** a `cv.aws10.atercates.cat` → Cloudflare DNS → Amplify CloudFront
2. **Amplify sirve** el sitio estático (HTML/CSS/JS con `config.js` generado)
3. **Frontend carga** y ejecuta `visitor-counter.js`
4. **JavaScript hace POST** a API Gateway → Lambda registra visita en DynamoDB
5. **JavaScript hace GET** a API Gateway → Lambda devuelve estadísticas
6. **Contador se actualiza** en la página con los datos recibidos

---

## 🛠️ Tecnologías

### Cloud Infrastructure (AWS)

| Servicio | Uso | Configuración |
|----------|-----|---------------|
| **AWS Amplify** | Static website hosting + CI/CD | Auto-build desde GitHub, custom domain |
| **Lambda** | Serverless backend (Python 3.11) | 128MB RAM, 10s timeout, LabRole |
| **API Gateway** | HTTP API para exponer Lambda | CORS habilitado, ruta `/visits` |
| **DynamoDB** | NoSQL database para visitas | On-demand billing, visitor_ip como key |
| **ACM** | SSL/TLS certificates | Auto-renovación, validación DNS |
| **S3** | Terraform state backend | Versionado + encriptación habilitados |
| **CloudWatch** | Logs y monitoring | Lambda logs + API Gateway logs |

### DNS & Networking

- **Cloudflare**: DNS management (Zone ID required)
- **Custom Domain**: `cv.aws10.atercates.cat`
- **HTTPS**: Forzado, certificado ACM automático

### Development Tools

| Categoría | Tecnología | Versión |
|-----------|------------|---------|
| **IaC** | Terraform | 1.6.0+ |
| **Language** | Python | 3.11 |
| **Testing** | pytest, pytest-cov, moto | Latest |
| **CI/CD** | GitHub Actions | - |
| **Version Control** | Git + GitHub | - |

### Frontend Stack

- **HTML5 + CSS3**: Responsive design
- **Vanilla JavaScript**: No frameworks, API fetch nativo
- **Google Fonts**: Inter font family

---

---

## 📁 Estructura del Proyecto

```
cloud-cv/
├── .github/
│   └── workflows/
│       ├── terraform-deploy.yml    # Pipeline principal de infraestructura
│       └── lambda-tests.yml        # Tests automáticos de Lambda
│
├── curriculum/                      # Frontend (Static Website)
│   ├── index.html                  # Página principal del CV
│   ├── config.js                   # Runtime config (auto-generado)
│   ├── images/                     # Assets e imágenes
│   ├── scripts/
│   │   └── visitor-counter.js      # Lógica del contador de visitas
│   └── styles/
│       └── main.css                # Estilos del sitio
│
├── lambda/                          # Backend Serverless
│   ├── visit_counter/
│   │   ├── handler.py              # Lambda function principal
│   │   └── requirements.txt        # Dependencias Python (boto3)
│   └── tests/
│       ├── test_handler.py         # Tests unitarios
│       ├── conftest.py             # Configuración pytest + moto
│       └── requirements-test.txt   # Dependencias de testing
│
├── terraform/                       # Infrastructure as Code
│   ├── backend.tf                  # S3 backend configuration
│   ├── main.tf                     # Orquestación de módulos
│   ├── providers.tf                # AWS + Cloudflare providers
│   ├── variables.tf                # Definición de variables
│   ├── terraform.tfvars            # Valores no sensibles (commiteado)
│   ├── terraform.tfvars.example    # Template de ejemplo
│   ├── outputs.tf                  # Outputs del deployment
│   └── modules/
│       ├── amplify/                # Amplify App + Domain
│       ├── dns/                    # ACM Certificates + Cloudflare
│       ├── dynamodb/               # DynamoDB table
│       └── lambda/                 # Lambda + API Gateway
│
├── scripts/
│   ├── init.sh                     # Inicialización S3 backend + terraform
│   └── generate-config.sh          # Generación de config.js (Amplify build)
│
├── .gitignore                       # Git ignore rules
└── README.md                        # Este archivo
```

### Archivos Clave

| Archivo | Propósito |
|---------|-----------|
| `terraform/backend.tf` | Configuración del backend S3 para state compartido |
| `terraform/terraform.tfvars` | Variables no sensibles (domain, region, etc.) |
| `lambda/visit_counter/handler.py` | Lógica del contador con DynamoDB |
| `curriculum/scripts/visitor-counter.js` | Cliente API para el frontend |
| `scripts/init.sh` | Script de inicialización (crea S3 + inicializa Terraform) |
| `.github/workflows/terraform-deploy.yml` | Pipeline de deployment |

---

## 🚀 Quick Start

### Prerrequisitos

```bash
# Herramientas necesarias
- AWS CLI >= 2.x
- Terraform >= 1.6.0
- Python >= 3.11
- Git
- Cuenta AWS con permisos (o AWS Academy Learner Lab)
- Dominio configurado en Cloudflare

# Verificar versiones
aws --version
terraform --version
python --version
```

### Configuración Inicial (Primera Vez)

**1. Clonar el repositorio**

```bash
git clone https://github.com/javifer-school/cloud-cv.git
cd cloud-cv
```

**2. Configurar credenciales AWS**

```bash
# AWS CLI
aws configure

# O usar variables de entorno (AWS Academy)
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_SESSION_TOKEN="your-token"  # Si usas AWS Academy
```

**3. Configurar variables de Terraform**

Edita `terraform/terraform.tfvars` con tus valores:

```hcl
# Domain Configuration
domain_name      = "cv.tu-dominio.com"
hosted_zone_name = "tu-dominio.com"

# GitHub Configuration
github_repository = "https://github.com/tu-usuario/cloud-cv"
github_branch     = "main"
```

**4. Configurar Cloudflare**

Necesitarás:
- `CLOUDFLARE_API_TOKEN`: Token API de Cloudflare
- `CLOUDFLARE_ZONE_ID`: ID de tu zona DNS

**5. Inicializar Terraform**

```bash
# Crea S3 bucket para state + inicializa Terraform
./scripts/init.sh
```

Este script:
- ✅ Crea bucket S3: `cloud-cv-terraform-state-{account_id}`
- ✅ Crea tabla DynamoDB: `cloud-cv-terraform-locks`
- ✅ Ejecuta `terraform init` con backend configurado
- ✅ Limpia recursos del state para evitar conflictos

**6. Desplegar infraestructura**

```bash
cd terraform

# Variables sensibles (se pasan como environment variables)
export TF_VAR_github_token="ghp_your_token"
export TF_VAR_lambda_role_arn="arn:aws:iam::123456789:role/LabRole"
export TF_VAR_cloudflare_api_token="your_cloudflare_token"
export TF_VAR_cloudflare_zone_id="your_zone_id"

# Plan
terraform plan

# Apply
terraform apply
```

**7. Verificar deployment**

```bash
# Obtener la URL del sitio
terraform output website_url

# Obtener URL del API
terraform output api_endpoint

# Visitar el sitio
open https://cv.tu-dominio.com  # macOS
# o
xdg-open https://cv.tu-dominio.com  # Linux
```

---

## ⚙️ Configuración Detallada

### Variables de Terraform

#### Variables No Sensibles (en `terraform.tfvars`)

```hcl
# AWS Configuration
aws_region = "us-east-1"

# Project Configuration
project_name = "cloud-cv"
environment  = "production"

# Domain Configuration
domain_name      = "cv.aws10.atercates.cat"
hosted_zone_name = "atercates.cat"

# GitHub Configuration
github_repository = "https://github.com/javifer-school/cloud-cv"
github_branch     = "main"

# DynamoDB Configuration
dynamodb_table_name = "cv-visit-counter"

# Lambda Configuration
lambda_function_name = "cv-visit-counter"
lambda_runtime       = "python3.11"
lambda_memory        = 128
lambda_timeout       = 10
```

#### Variables Sensibles (via environment o secrets)

```bash
# GitHub Token (para Amplify auto-build)
export TF_VAR_github_token="ghp_xxxxxxxxxxxx"

# Lambda IAM Role (AWS Academy LabRole)
export TF_VAR_lambda_role_arn="arn:aws:iam::ACCOUNT_ID:role/LabRole"

# Cloudflare (para DNS management)
export TF_VAR_cloudflare_api_token="your_token"
export TF_VAR_cloudflare_zone_id="your_zone_id"
```

### Secretos de GitHub (para CI/CD)

Configura estos secretos en `Settings → Secrets and variables → Actions`:

| Secret Name | Descripción | Ejemplo |
|-------------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key | `AKIAXXXXXXXXXXXXXXXX` |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key | `xxxxxxxxxxxx` |
| `AWS_SESSION_TOKEN` | AWS Session Token (si usas AWS Academy) | `IQoJb3JpZ2luX2...` |
| `GH_TOKEN_AMPLIFY` | GitHub Personal Access Token | `ghp_xxxxxx` |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API Token | `xxxxxxxxxx` |
| `CLOUDFLARE_ZONE_ID` | Cloudflare Zone ID | `a436467d0e2f...` |
| `LAMBDA_ROLE_ARN` | IAM Role ARN para Lambda | `arn:aws:iam::...` |

---

---

## 🔄 CI/CD Pipelines

El proyecto utiliza **GitHub Actions** para automatización completa del ciclo de vida.

### Pipeline 1: Terraform Deploy

**Triggers:**
- Push a `main` con cambios en `terraform/**` o `lambda/**`
- Pull Request a `main`
- Manual dispatch

**Flujo:**

```mermaid
graph LR
    A[Git Push] --> B[Checkout Code]
    B --> C[Setup Terraform 1.6.0]
    C --> D[Configure AWS Credentials]
    D --> E[Init S3 Backend]
    E --> F[Terraform Init]
    F --> G[Terraform Format Check]
    G --> H[Terraform Validate]
    H --> I{Terraform Plan}
    I -->|Changes Detected| J[Terraform Apply]
    I -->|No Changes| K[Skip Apply]
    J --> L[Deploy Complete]
```

**Pasos detallados:**

1. **Checkout**: Clona el código
2. **Setup Terraform**: Instala Terraform 1.6.0
3. **Configure AWS**: Configura credentials (incluye session token para AWS Academy)
4. **Setup S3 Backend**: Ejecuta `init.sh --ci` para crear/verificar bucket S3
5. **Terraform Init**: Inicializa con backend S3 dinámico
6. **Terraform Format**: Verifica formatting (`terraform fmt -check`)
7. **Terraform Validate**: Valida sintaxis
8. **Terraform Plan**: Genera plan de cambios (salida en artifact)
9. **Terraform Apply**: Aplica cambios solo en push a `main` o manual

**Variables requeridas:**
- `TF_VAR_github_token`
- `TF_VAR_cloudflare_api_token`
- `TF_VAR_cloudflare_zone_id`
- `TF_VAR_lambda_role_arn`

### Pipeline 2: Lambda Tests

**Triggers:**
- Push a `main` con cambios en `lambda/**`
- Pull Request a `main`
- Manual dispatch

**Flujo:**

```
Git Push → Checkout → Setup Python 3.11 → Install Dependencies → 
Run pytest → Coverage Report → Upload to Codecov → Comment PR
```

**Pasos:**

1. **Checkout Code**
2. **Setup Python 3.11**: Con cache de pip
3. **Install Dependencies**: `pytest`, `moto`, `boto3`
4. **Run Tests**: `pytest -v --cov --cov-report=xml`
5. **Upload Coverage**: A Codecov (opcional)
6. **Comment PR**: Con % de coverage en PRs

---

### Estado de Terraform (S3 Backend)

El estado de Terraform se almacena en **S3** para persistencia entre ejecuciones:

- **Bucket**: `cloud-cv-terraform-state-{account_id}`
- **Key**: `terraform.tfstate`
- **Lock Table**: `cloud-cv-terraform-locks` (DynamoDB)
- **Features**: Versionado, encriptación, public access blocked

**Ventajas:**
✅ Estado compartido entre local y CI/CD
✅ Locking para evitar conflictos
✅ Historial de cambios (versionado)
✅ Cifrado en reposo

---

## 🧪 Testing

### Test Suite

El proyecto incluye una suite completa de tests unitarios para la Lambda function.

**Tecnologías de testing:**
- `pytest`: Framework de testing
- `pytest-cov`: Coverage reporting
- `moto`: Mock de servicios AWS (DynamoDB)

### Ejecutar Tests Localmente

```bash
# Navegar al directorio lambda
cd lambda

# Instalar dependencias de testing
pip install -r tests/requirements-test.txt

# Ejecutar tests básicos
pytest tests/ -v

# Ejecutar con coverage
pytest tests/ -v --cov=visit_counter

# Generar reporte HTML
pytest tests/ --cov=visit_counter --cov-report=html
open htmlcov/index.html  # Ver reporte en browser
```

### Casos de Prueba

| Test | Descripción |
|------|-------------|
| `test_get_visitor_ip` | Extracción de IP de diferentes headers |
| `test_cors_headers` | Validación de headers CORS |
| `test_lambda_handler_get` | GET request con DynamoDB mock |
| `test_lambda_handler_post` | POST request registrando visita |
| `test_error_handling` | Manejo de errores y excepciones |
| `test_decimal_encoder` | Serialización JSON de Decimals |
| `test_full_integration` | Flujo completo GET + POST |

### Coverage Target

**Objetivo**: >90% code coverage

**Último reporte:**
```
visit_counter/handler.py    96%    (120/125 statements)
```

### Tests en CI/CD

Los tests se ejecutan **automáticamente** en cada:
- Push a `main` que modifique `lambda/**`
- Pull Request

Si los tests fallan, el pipeline se detiene y no se despliega.

---

## 📡 API Reference

### Base URL

```
https://{api-gateway-id}.execute-api.us-east-1.amazonaws.com
```

Obtener URL real:
```bash
terraform output api_gateway_url
```

### Endpoints

#### GET /visits

Obtiene estadísticas de visitas del sitio.

**Headers:**
```
Accept: application/json
```

**Response 200 OK:**
```json
{
  "total_visits": 150,
  "unique_visitors": 42,
  "visitor_ip": "192.168.1.1",
  "visitor_visits": 3,
  "first_visit": "2026-01-01T10:00:00Z",
  "last_visit": "2026-01-08T15:30:00Z"
}
```

**CORS Headers:**
```
Access-Control-Allow-Origin: https://cv.aws10.atercates.cat
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: Content-Type
```

#### POST /visits

Registra una nueva visita del usuario actual.

**Headers:**
```
Content-Type: application/json
```

**Response 200 OK:**
```json
{
  "message": "Visit registered successfully",
  "visitor_ip": "192.168.1.1",
  "visitor_visits": 4,
  "total_visits": 151
}
```

**Error Responses:**

| Code | Descripción |
|------|-------------|
| 500 | Error interno del servidor (DynamoDB issue) |
| 405 | Método HTTP no permitido |

### Rate Limiting

- No implementado actualmente
- DynamoDB On-Demand scaling maneja spikes de tráfico

### Frontend Integration

```javascript
// Cargar configuración
const API_ENDPOINT = window.__CONFIG__.API_ENDPOINT;
const VISITS_URL = `${API_ENDPOINT}/visits`;

// Registrar visita
async function registerVisit() {
    const response = await fetch(VISITS_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
    });
    return await response.json();
}

// Obtener estadísticas
async function getVisitStats() {
    const response = await fetch(VISITS_URL);
    return await response.json();
}
```

---

## 🐛 Troubleshooting

### Problemas Comunes

#### 1. Error: "No region specified" en tests

**Problema:**
```
botocore.exceptions.NoRegionError: You must specify a region.
```

**Solución:**
```bash
export AWS_DEFAULT_REGION=us-east-1
pytest tests/
```

#### 2. Terraform: Backend initialization failed

**Problema:**
```
Error: Failed to get existing workspaces: S3 bucket does not exist
```

**Solución:**
```bash
# Re-ejecutar init script
./scripts/init.sh
```

#### 3. Amplify build failed

**Problema:** El sitio no se actualiza después de un push

**Solución:**
```bash
# Verificar build status
aws amplify list-jobs \
  --app-id $(terraform output -raw amplify_app_id) \
  --branch-name main

# Forzar nuevo build
aws amplify start-job \
  --app-id $(terraform output -raw amplify_app_id) \
  --branch-name main \
  --job-type RELEASE
```

#### 4. Contador de visitas no funciona

**Checks:**

1. **Verificar config.js existe y tiene API endpoint correcto:**
```bash
curl https://cv.tu-dominio.com/config.js
```

2. **Verificar API Gateway responde:**
```bash
API_URL=$(terraform output -raw api_endpoint)
curl "$API_URL"
```

3. **Verificar Lambda logs:**
```bash
aws logs tail /aws/lambda/cv-visit-counter --follow
```

4. **Verificar CORS headers:**
```bash
curl -H "Origin: https://cv.tu-dominio.com" \
     -H "Access-Control-Request-Method: GET" \
     -X OPTIONS \
     $API_URL
```

#### 5. AWS Academy Session Token Expired

**Problema:**
```
An error occurred (ExpiredToken): The security token included in the request is expired
```

**Solución:**
```bash
# Renovar credentials en AWS Academy Learner Lab
# Copiar nuevas credentials
# Actualizar GitHub Secrets:
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY  
# - AWS_SESSION_TOKEN
```

#### 6. Terraform state locked

**Problema:**
```
Error: Error acquiring the state lock
```

**Solución:**
```bash
# Verificar lock en DynamoDB
aws dynamodb scan --table-name cloud-cv-terraform-locks

# Si es un lock antiguo, forzar unlock
terraform force-unlock LOCK_ID
```

### Debug Mode

Activar logs detallados:

```bash
# Terraform
export TF_LOG=DEBUG
terraform plan

# AWS CLI
aws --debug s3 ls

# Lambda (CloudWatch)
aws logs tail /aws/lambda/cv-visit-counter \
  --follow \
  --format short
```

---

## 👤 Autor

**Javier Fernández**

- GitHub: [@javifer-school](https://github.com/javifer-school)
- Proyecto: Cloud CV - AWS Cloud Resume Challenge
- Institución: CFGS ASIX

---

**⭐ Si este proyecto te ha sido útil, considera darle una estrella en GitHub**

---

Desarrollado como parte del **Cloud Resume Challenge** - Institut ITIC Barcelona 2026
