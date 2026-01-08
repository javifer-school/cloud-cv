# 🚀 Plan de Infraestructura AWS - Cloud CV

## 📋 Resumen del Proyecto

**Repositorio:** https://github.com/javifer-school/cloud-cv  
**Rama principal:** `main`  
**Dominio:** `cv.aws10.atercates.cat`  
**Presentación:** Lunes 12 de enero de 2026

---

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────────────┐
│                         GITHUB REPOSITORY                            │
│                  github.com/javifer-school/cloud-cv                  │
│                              (main)                                  │
└─────────────────┬───────────────────────────────┬───────────────────┘
                  │                               │
                  ▼                               ▼
┌─────────────────────────────┐   ┌─────────────────────────────────┐
│     GitHub Actions CI/CD    │   │      GitHub Actions CI/CD       │
│        (Frontend)           │   │         (Backend)               │
│  - Build Hugo/Static        │   │  - Run Python Tests             │
│  - Deploy to Amplify        │   │  - Deploy Lambda                │
└─────────────┬───────────────┘   └───────────────┬─────────────────┘
              │                                   │
              ▼                                   ▼
┌─────────────────────────────┐   ┌─────────────────────────────────┐
│       AWS AMPLIFY           │   │         AWS LAMBDA              │
│    (Static Website)         │   │    (Python - visit_counter)    │
│  cv.aws10.atercates.cat     │   │                                 │
└─────────────┬───────────────┘   └───────────────┬─────────────────┘
              │                                   │
              │                                   ▼
              │                   ┌─────────────────────────────────┐
              │                   │       API GATEWAY               │
              │                   │    /api/visits (GET/POST)       │
              │                   └───────────────┬─────────────────┘
              │                                   │
              │                                   ▼
              │                   ┌─────────────────────────────────┐
              │                   │        DYNAMODB                 │
              │                   │   Table: cv-visit-counter       │
              │                   │   PK: visitor_ip                │
              │                   │   Attr: visit_count, last_visit │
              │                   └─────────────────────────────────┘
              │
              ▼
┌─────────────────────────────┐
│         ROUTE 53            │
│  cv.aws10.atercates.cat     │
│         + ACM               │
│    (HTTPS Certificate)      │
└─────────────────────────────┘
```

---

## 📁 Estructura del Repositorio

```
cloud-cv/
├── .github/
│   └── workflows/
│       ├── frontend-deploy.yml      # CI/CD para Amplify
│       ├── backend-deploy.yml       # CI/CD para Lambda
│       └── terraform-deploy.yml     # CI/CD para Terraform
│
├── curriculum/                       # Código del CV (Hugo/Static)
│   ├── index.html
│   ├── styles/
│   │   └── main.css
│   └── scripts/
│       └── visitor-counter.js
│
├── lambda/                           # Código de la Lambda
│   ├── visit_counter/
│   │   ├── __init__.py
│   │   ├── handler.py               # Handler principal
│   │   └── requirements.txt
│   └── tests/
│       ├── __init__.py
│       ├── test_handler.py          # Unit tests
│       └── conftest.py              # Fixtures pytest
│
├── terraform/                        # Infrastructure as Code
│   ├── main.tf                      # Configuración principal
│   ├── variables.tf                 # Variables globales
│   ├── outputs.tf                   # Outputs
│   ├── providers.tf                 # Providers AWS
│   ├── backend.tf                   # S3 backend para state
│   │
│   └── modules/
│       ├── dynamodb/                # Módulo DynamoDB
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       │
│       ├── lambda/                  # Módulo Lambda + API Gateway
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       │
│       ├── amplify/                 # Módulo Amplify
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       │
│       └── dns/                     # Módulo Route53 + ACM
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
│
├── PLAN_INFRAESTRUCTURA.md          # Este documento
└── README.md                        # Documentación general
```

---

## 🔧 Componentes Detallados

### 1. Frontend - AWS Amplify

| Propiedad | Valor |
|-----------|-------|
| **Servicio** | AWS Amplify Hosting |
| **Repositorio** | github.com/javifer-school/cloud-cv |
| **Rama** | main |
| **Directorio** | /curriculum |
| **Dominio** | cv.aws10.atercates.cat |
| **HTTPS** | Sí (ACM Certificate) |

**Funcionalidad:**
- Hosting de sitio web estático
- Auto-deploy en cada push a main
- CDN integrado

---

### 2. Backend - AWS Lambda

| Propiedad | Valor |
|-----------|-------|
| **Servicio** | AWS Lambda |
| **Runtime** | Python 3.11 |
| **Nombre** | cv-visit-counter |
| **Memory** | 128 MB |
| **Timeout** | 10 segundos |
| **Handler** | handler.lambda_handler |

**Funcionalidad:**
- Registrar visitas por IP
- Retornar contador de visitas
- CORS habilitado

---

### 3. API - API Gateway

| Propiedad | Valor |
|-----------|-------|
| **Tipo** | HTTP API (v2) |
| **Endpoint** | /api/visits |
| **Métodos** | GET, POST |
| **CORS** | Habilitado |

**Endpoints:**

| Método | Path | Descripción |
|--------|------|-------------|
| GET | /api/visits | Obtener total de visitas y visitas por IP |
| POST | /api/visits | Registrar nueva visita |

---

### 4. Base de Datos - DynamoDB

| Propiedad | Valor |
|-----------|-------|
| **Tabla** | cv-visit-counter |
| **Partition Key** | visitor_ip (String) |
| **Billing Mode** | PAY_PER_REQUEST |
| **Backup** | Point-in-time recovery habilitado |

**Esquema de datos:**

```json
{
  "visitor_ip": "192.168.1.1",
  "visit_count": 5,
  "first_visit": "2026-01-08T10:30:00Z",
  "last_visit": "2026-01-08T15:45:00Z"
}
```

---

### 5. DNS - Route53 + ACM

| Propiedad | Valor |
|-----------|-------|
| **Dominio** | cv.aws10.atercates.cat |
| **Zona** | atercates.cat (existente) |
| **Certificado** | ACM (us-east-1 para Amplify) |
| **Tipo registro** | CNAME / Alias |

---

## 🔄 CI/CD Pipelines

### Frontend Pipeline (frontend-deploy.yml)

```
Push to main → Build Static Site → Deploy to Amplify
```

**Triggers:** Push a `main` (cambios en `/curriculum`)  
**Jobs:**
1. Checkout código
2. Build (si hay generador)
3. Deploy a Amplify

### Backend Pipeline (backend-deploy.yml)

```
Push to main → Run Tests → Package Lambda → Deploy Lambda
```

**Triggers:** Push a `main` (cambios en `/lambda`)  
**Jobs:**
1. Checkout código
2. Setup Python 3.11
3. Install dependencies
4. Run pytest
5. Package Lambda (zip)
6. Deploy a AWS Lambda

### Infrastructure Pipeline (terraform-deploy.yml)

```
Push to main → Terraform Plan → (Manual Approval) → Terraform Apply
```

**Triggers:** Push a `main` (cambios en `/terraform`)  
**Jobs:**
1. Checkout código
2. Setup Terraform
3. Terraform init
4. Terraform plan
5. Terraform apply (manual o automático)

---

## 🔐 Secretos de GitHub Necesarios

| Secreto | Descripción |
|---------|-------------|
| `AWS_ACCESS_KEY_ID` | Access Key de IAM |
| `AWS_SECRET_ACCESS_KEY` | Secret Key de IAM |
| `AWS_REGION` | Región AWS (eu-west-1) |

---

## 📊 Estimación de Costos (Free Tier)

| Servicio | Coste Estimado |
|----------|---------------|
| Amplify | Gratis (Free Tier: 1000 min build/mes) |
| Lambda | Gratis (Free Tier: 1M requests/mes) |
| API Gateway | Gratis (Free Tier: 1M calls/mes) |
| DynamoDB | Gratis (Free Tier: 25 GB) |
| Route53 | ~$0.50/mes (hosted zone) |
| ACM | Gratis |
| **TOTAL** | **~$0.50/mes** |

---

## ✅ Checklist de Implementación

### Fase 1: Infraestructura Base
- [ ] Crear módulos Terraform
- [ ] Configurar backend S3 para state
- [ ] Desplegar DynamoDB
- [ ] Desplegar Lambda + API Gateway
- [ ] Configurar Route53 + ACM
- [ ] Desplegar Amplify

### Fase 2: Código
- [ ] Crear Lambda en Python
- [ ] Escribir tests para Lambda
- [ ] Crear web estática del CV
- [ ] Integrar contador de visitas JS

### Fase 3: CI/CD
- [ ] Configurar workflow frontend
- [ ] Configurar workflow backend
- [ ] Configurar workflow terraform
- [ ] Probar pipelines

### Fase 4: Validación
- [ ] Verificar HTTPS funcionando
- [ ] Verificar contador de visitas
- [ ] Verificar auto-deploy
- [ ] Documentar todo

---

## 🚀 Próximos Pasos

1. **Ahora:** Crear toda la estructura de código
2. **Después:** Configurar secretos en GitHub
3. **Finalmente:** Ejecutar Terraform y validar

---

**Última actualización:** 8 de enero de 2026  
**Estado:** 🟢 Plan definido - Implementación en curso
