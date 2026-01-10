# Cloud CV - AWS Cloud Resume Challenge

[![Frontend Deploy](https://github.com/javifer-school/cloud-cv/actions/workflows/frontend-deploy.yml/badge.svg)](https://github.com/javifer-school/cloud-cv/actions/workflows/frontend-deploy.yml)
[![Backend Deploy](https://github.com/javifer-school/cloud-cv/actions/workflows/backend-deploy.yml/badge.svg)](https://github.com/javifer-school/cloud-cv/actions/workflows/backend-deploy.yml)
[![Terraform Deploy](https://github.com/javifer-school/cloud-cv/actions/workflows/terraform-deploy.yml/badge.svg)](https://github.com/javifer-school/cloud-cv/actions/workflows/terraform-deploy.yml)

## 📋 Descripción

Este proyecto implementa el [Cloud Resume Challenge](https://cloudresumechallenge.dev/docs/the-challenge/aws/) en AWS, desplegando un curriculum vitae online con contador de visitas usando infraestructura serverless.

🌐 **URL**: https://cv.aws10.atercates.cat

### ⚡ Quick Links

- 📖 [Guía de Configuración Completa](SETUP_GUIDE.md) - Variables y credenciales
- 🗺️ [Mapa de Configuración Visual](CONFIG_MAP.md) - Dónde va cada variable
- 🚀 [Guía de CI/CD](CICD_GUIDE.md) - Workflows de GitHub Actions
- 📝 [Comandos Útiles](COMMANDS.md) - Make, Terraform, AWS CLI
- 📋 [Plan de Infraestructura](PLAN_INFRAESTRUCTURA.md) - Arquitectura detallada

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

### Quick Start

```bash
# 1. Verificar que todo esté listo
make check

# 2. Instalar dependencias
make init

# 3. Ejecutar tests
make test

# 4. Desplegar infraestructura
make tf-apply
```

### Variables de Entorno / Secretos de GitHub

Configura estos secretos en tu repositorio de GitHub:

| Secreto | Descripción |
|---------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key |
| `GH_TOKEN_AMPLIFY` | Token de GitHub para Amplify |

Para más detalles sobre secretos, ver [CICD_GUIDE.md](CICD_GUIDE.md)

### Despliegue Manual

```bash
# 1. Clonar repositorio
git clone https://github.com/javifer-school/cloud-cv.git
cd cloud-cv

# 2. Inicializar Terraform con S3 backend (UNA VEZ)
./scripts/init.sh

# 3. Planificar
cd terraform
terraform plan

# 4. Aplicar
terraform apply
```

**📝 Notas importantes:**
- El script `init.sh` configura automáticamente el backend S3
- Solo necesitas ejecutarlo **una vez** por cuenta AWS
- Las variables sensibles se cargan desde el archivo `terraform.tfvars` localmente
- En CI/CD, las variables sensibles vienen de secrets de GitHub

### Despliegue Automático (CI/CD)

Los cambios en `main` activan automáticamente los pipelines correspondientes:

| Cambios en | Workflow | Acciones |
|-----------|----------|----------|
| `/curriculum/**` | Frontend Deploy | Build → Deploy a Amplify |
| `/lambda/**` | Backend Deploy | Tests → Package → Deploy Lambda |
| `/terraform/**` | Terraform Deploy | Format → Validate → Plan → Apply |

📖 **Guía completa de CI/CD:** [CICD_GUIDE.md](CICD_GUIDE.md)

## 🧪 Tests

### Ejecutar tests localmente

```bash
# Opción 1: Con Make
make test          # Tests básicos
make test-cov      # Tests con coverage
make dev-test      # Tests + abrir reporte HTML

# Opción 2: Manual
cd lambda
pip install -r tests/requirements-test.txt
pytest tests/ -v --cov=visit_counter
```

### Coverage esperado

El proyecto incluye 20+ tests unitarios que cubren:
- ✅ Extracción de IP de visitante
- ✅ Headers CORS
- ✅ Manejo de GET/POST requests
- ✅ Operaciones DynamoDB
- ✅ Gestión de errores
- ✅ Integración completa

Target: **>90% coverage**

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
