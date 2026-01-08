# Cloud CV - AWS Cloud Resume Challenge

[![Frontend Deploy](https://github.com/javifer-school/cloud-cv/actions/workflows/frontend-deploy.yml/badge.svg)](https://github.com/javifer-school/cloud-cv/actions/workflows/frontend-deploy.yml)
[![Backend Deploy](https://github.com/javifer-school/cloud-cv/actions/workflows/backend-deploy.yml/badge.svg)](https://github.com/javifer-school/cloud-cv/actions/workflows/backend-deploy.yml)
[![Terraform Deploy](https://github.com/javifer-school/cloud-cv/actions/workflows/terraform-deploy.yml/badge.svg)](https://github.com/javifer-school/cloud-cv/actions/workflows/terraform-deploy.yml)

## 📋 Descripción

Este proyecto implementa el [Cloud Resume Challenge](https://cloudresumechallenge.dev/docs/the-challenge/aws/) en AWS, desplegando un curriculum vitae online con contador de visitas usando infraestructura serverless.

🌐 **URL**: https://cv.aws10.atercates.cat

## 🏗️ Arquitectura

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   GitHub Repo   │────▶│  GitHub Actions │────▶│   AWS Amplify   │
│   (Frontend)    │     │    (CI/CD)      │     │  (Static Site)  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   DynamoDB      │◀────│   AWS Lambda    │◀────│  API Gateway    │
│  (Visit Data)   │     │    (Python)     │     │   (HTTP API)    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

## 📁 Estructura del Proyecto

```
cloud-cv/
├── .github/workflows/       # CI/CD pipelines
│   ├── frontend-deploy.yml
│   ├── backend-deploy.yml
│   └── terraform-deploy.yml
├── curriculum/              # Frontend (HTML/CSS/JS)
│   ├── index.html
│   ├── styles/
│   └── scripts/
├── lambda/                  # Backend (Python)
│   ├── visit_counter/
│   └── tests/
├── terraform/               # Infrastructure as Code
│   ├── main.tf
│   └── modules/
│       ├── amplify/
│       ├── dynamodb/
│       ├── dns/
│       └── lambda/
└── README.md
```

## 🚀 Despliegue

### Prerrequisitos

- Cuenta AWS con permisos adecuados
- Terraform >= 1.0.0
- Python 3.11+
- Zona DNS `atercates.cat` configurada en Route53

### Variables de Entorno / Secretos de GitHub

Configura estos secretos en tu repositorio de GitHub:

| Secreto | Descripción |
|---------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key |
| `GH_TOKEN_AMPLIFY` | Token de GitHub para Amplify |

### Despliegue Manual

```bash
# 1. Clonar repositorio
git clone https://github.com/javifer-school/cloud-cv.git
cd cloud-cv

# 2. Inicializar Terraform
cd terraform
terraform init

# 3. Planificar
terraform plan -var="github_token=YOUR_TOKEN"

# 4. Aplicar
terraform apply -var="github_token=YOUR_TOKEN"
```

### Despliegue Automático

Los cambios en `main` activan automáticamente los pipelines correspondientes:
- Cambios en `/curriculum` → Frontend Deploy
- Cambios en `/lambda` → Backend Deploy (con tests)
- Cambios en `/terraform` → Terraform Plan/Apply

## 🧪 Tests

```bash
# Ejecutar tests de la Lambda
cd lambda
pip install -r tests/requirements-test.txt
pytest tests/ -v --cov=visit_counter
```

## 📊 API Endpoints

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/visits` | Obtener estadísticas de visitas |
| POST | `/visits` | Registrar nueva visita |

### Ejemplo de respuesta GET:

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

## 🛠️ Tecnologías

| Componente | Tecnología |
|------------|------------|
| Frontend | HTML, CSS, JavaScript |
| Backend | Python 3.11, AWS Lambda |
| Database | DynamoDB |
| API | API Gateway (HTTP API) |
| Hosting | AWS Amplify |
| DNS | Route53 |
| HTTPS | ACM |
| IaC | Terraform |
| CI/CD | GitHub Actions |

## 📝 Licencia

Este proyecto es parte de un ejercicio educativo del CFGS ASIX.

## 👤 Autor

- GitHub: [@javifer-school](https://github.com/javifer-school)

---

Desarrollado como parte del **Cloud Resume Challenge** - Institut ITIC Barcelona 2026
