# 📋 Resumen de Revisión y Correcciones de Pipelines

## 🔍 Análisis Realizado

He revisado completamente las 3 pipelines de CI/CD del proyecto `cloud-cv` con enfoque en usar la región **`us-east-1`** en lugar de `eu-west-1`.

---

## ✅ Cambios Realizados

### 1. **Actualización de Región AWS en Workflows**

Todos los workflows fueron actualizados para usar `us-east-1`:

| Archivo | Cambio | Línea |
|---------|--------|-------|
| `.github/workflows/frontend-deploy.yml` | `AWS_REGION: eu-west-1` → `AWS_REGION: us-east-1` | 18 |
| `.github/workflows/backend-deploy.yml` | `AWS_REGION: eu-west-1` → `AWS_REGION: us-east-1` | 23 |
| `.github/workflows/terraform-deploy.yml` | `AWS_REGION: eu-west-1` → `AWS_REGION: us-east-1` | 32 |

### 2. **Documentación de Configuración**

Se creó archivo: `GITHUB_SECRETS_SETUP.md` con:
- ✅ Paso a paso para crear credenciales AWS
- ✅ Cómo crear GitHub Personal Access Token
- ✅ Cómo agregar secretos a GitHub Actions
- ✅ Verificación de configuración
- ✅ Troubleshooting
- ✅ Checklist completo

---

## 🔐 Secretos Necesarios en GitHub Actions

Debes configurar exactamente **3 secretos** en: **Settings → Secrets and variables → Actions**

### Tabla de Secretos Requeridos

| Secreto | Descripción | Dónde Obtenerlo | Obligatorio |
|---------|-------------|-----------------|------------|
| **AWS_ACCESS_KEY_ID** | Access Key de AWS IAM User | AWS Console → IAM → Users → Create access key | ✅ SÍ |
| **AWS_SECRET_ACCESS_KEY** | Secret Key de AWS IAM User | AWS Console → IAM → Users → Create access key | ✅ SÍ |
| **GH_TOKEN_AMPLIFY** | GitHub Personal Access Token | GitHub → Settings → Developer settings → Personal tokens | ✅ SÍ |

---

## 📝 Cómo Crear Cada Secreto

### Secreto 1: AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY

**En AWS Console:**

```
1. Ir a: IAM → Users → Create user
   Nombre: cloud-cv-deployer

2. Asignar Permisos (cualquiera de):
   - Adjuntar políticas individuales (Lambda, DynamoDB, Amplify, etc.)
   - O usar política mínima personalizada

3. Crear Access Key:
   - Security credentials → Create access key
   - Seleccionar: CLI
   - Copiar: Access Key ID y Secret Access Key
```

⚠️ **Importante:** El Secret Access Key solo se muestra una vez, descárgalo en CSV

### Secreto 2: GH_TOKEN_AMPLIFY

**En GitHub:**

```
1. Ir a: Settings → Developer settings → Personal access tokens → Tokens (classic)

2. Click: Generate new token (classic)
   Nombre: Cloud CV Amplify Token
   Expiration: 90 days (recomendado)

3. Seleccionar Scopes:
   ✅ repo (Full control of private repositories)
   ✅ user:email (Access user email addresses)

4. Copiar el token generado (aparece solo una vez)
```

### Agregar Secretos a GitHub

**Opción A: UI Web**

```
Repository → Settings → Secrets and variables → Actions
→ New repository secret
  Name: AWS_ACCESS_KEY_ID
  Secret: AKIA2BXNZ3A7EXAMPLE
→ Add secret
```

Repetir para los otros 2 secretos.

**Opción B: GitHub CLI**

```bash
gh secret set AWS_ACCESS_KEY_ID -b "AKIA2BXNZ3A7EXAMPLE"
gh secret set AWS_SECRET_ACCESS_KEY -b "wJalrXUtnFEMI/K7MDENGbPxRfCHEXAMPLEKEY"
gh secret set GH_TOKEN_AMPLIFY -b "ghp_5g6h7j8k9l0m1n2o3p4q5r6s7t8u9v0w"
```

---

## 🌍 Configuración de Región

### Verificar Coherencia

Asegúrate de que todos estos apunten a **`us-east-1`**:

| Ubicación | Valor Actual | Verificar |
|-----------|--------------|-----------|
| `terraform/terraform.tfvars` | `aws_region = "us-east-1"` | ✅ Correcto |
| `frontend-deploy.yml` | `AWS_REGION: us-east-1` | ✅ Actualizado |
| `backend-deploy.yml` | `AWS_REGION: us-east-1` | ✅ Actualizado |
| `terraform-deploy.yml` | `AWS_REGION: us-east-1` | ✅ Actualizado |

---

## 🚀 Cómo Funcionan las Pipelines

### Pipeline 1: Frontend Deploy
```
Trigger: Push a main con cambios en /curriculum/**
├── Checkout código
├── Configurar AWS credentials (usa AWS_ACCESS_KEY_ID y AWS_SECRET_ACCESS_KEY)
├── Obtener ID de app Amplify
├── Disparar build en Amplify
└── ✅ Sitio online en cv.aws10.atercates.cat
```

### Pipeline 2: Backend Deploy
```
Trigger: Push/PR a main con cambios en /lambda/**
├── Test Job:
│   ├── Instalar dependencias Python
│   ├── Ejecutar pytest
│   └── Subir reporte de cobertura
├── Deploy Job (solo en main):
│   ├── Empaquetar código Lambda
│   ├── Configurar AWS credentials
│   ├── Actualizar función Lambda
│   └── ✅ Lambda actualizada
```

### Pipeline 3: Terraform Deploy
```
Trigger: Push/PR a main con cambios en /terraform/**
├── Format: Validar formato
├── Validate: Validar sintaxis
├── Plan: Generar plan de cambios
├── Apply (solo en main o manual):
│   ├── Descargar plan anterior
│   ├── Aplicar cambios
│   └── ✅ Infraestructura actualizada
```

---

## ✅ Checklist Pre-despliegue

- [ ] **IAM User creado en AWS**
  - Nombre: `cloud-cv-deployer`
  - Permisos: Lambda, DynamoDB, Amplify, Route53, ACM, IAM, etc.

- [ ] **Access Keys creadas y guardadas**
  - [ ] Access Key ID (`AKIA...`)
  - [ ] Secret Access Key (`wJal...`)

- [ ] **GitHub Personal Token creado**
  - [ ] Token creado
  - [ ] Scopes: `repo`, `user:email`
  - [ ] Guardado en lugar seguro

- [ ] **Secretos agregados a GitHub**
  - [ ] `AWS_ACCESS_KEY_ID`
  - [ ] `AWS_SECRET_ACCESS_KEY`
  - [ ] `GH_TOKEN_AMPLIFY`

- [ ] **Configuración de región verificada**
  - [ ] `terraform/terraform.tfvars`: `us-east-1`
  - [ ] `frontend-deploy.yml`: `us-east-1`
  - [ ] `backend-deploy.yml`: `us-east-1`
  - [ ] `terraform-deploy.yml`: `us-east-1`

- [ ] **Zona DNS creada en Route53**
  - [ ] Zona: `atercates.cat`
  - [ ] Nameservers actualizados en registrador

---

## 📞 Troubleshooting Común

### ❌ Error: "InvalidClientTokenId" o "UnauthorizedOperation"
**Causa:** Credenciales AWS inválidas o sin permisos
**Solución:**
1. Verificar que Access Key y Secret Key sean correctos
2. Validar que el usuario IAM tenga los permisos necesarios
3. Regenerar las credenciales si fue necesario

### ❌ Error: "Forbidden to perform: amplify:..."
**Causa:** Usuario sin permisos para Amplify
**Solución:** Agregar `AWSAmplifyFullAccess` al usuario IAM

### ❌ Error: "github_token not specified"
**Causa:** `GH_TOKEN_AMPLIFY` no configurado en GitHub
**Solución:** Crear y agregar GitHub Personal Access Token

### ❌ Error: "Region us-east-1 does not exist"
**Causa:** Región mal escrita
**Solución:** Verificar que sea `us-east-1` (no `us-east-1a`, `us-west-1`, etc.)

---

## 📚 Documentación Disponible

- **GITHUB_SECRETS_SETUP.md** - Guía detallada de configuración (NUEVO)
- **SETUP_GUIDE.md** - Configuración general del proyecto
- **CICD_GUIDE.md** - Detalles de pipelines
- **CONFIG_MAP.md** - Mapa visual de variables
- **PLAN_INFRAESTRUCTURA.md** - Arquitectura AWS

---

## 🎯 Próximos Pasos

1. **Crear IAM User en AWS** (si no lo has hecho)
2. **Generar Access Keys y GitHub Token**
3. **Agregar los 3 secretos a GitHub Actions**
4. **Verificar que la región sea `us-east-1` en todos lados**
5. **Crear zona DNS en Route53** (si no existe)
6. **Hacer un push a `main`** para disparar las pipelines

---

✅ **Con esta configuración, las pipelines de CI/CD están listas para funcionar correctamente.**
