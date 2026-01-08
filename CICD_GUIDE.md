# 🚀 Guía de CI/CD - Cloud CV

## 📋 Workflows Disponibles

El proyecto incluye 3 pipelines automatizados de GitHub Actions:

### 1. Frontend Deploy (`frontend-deploy.yml`)
Despliega cambios en el sitio web a AWS Amplify.

**Trigger:**
- Push a `main` con cambios en `/curriculum/**`
- Dispatch manual

**Proceso:**
1. ✅ Checkout del código
2. ✅ Configurar credenciales AWS
3. ✅ Obtener ID de app Amplify
4. ✅ Lanzar build en Amplify

### 2. Backend Deploy (`backend-deploy.yml`)
Ejecuta tests y despliega la función Lambda.

**Trigger:**
- Push a `main` con cambios en `/lambda/**`
- Pull Request con cambios en `/lambda/**`
- Dispatch manual

**Proceso:**
1. **Test Job:**
   - ✅ Setup Python 3.11
   - ✅ Instalar dependencias de test
   - ✅ Ejecutar pytest con coverage
   - ✅ Subir reporte de cobertura

2. **Deploy Job** (solo en push a main):
   - ✅ Empaquetar código Lambda
   - ✅ Crear deployment package (ZIP)
   - ✅ Actualizar función Lambda en AWS
   - ✅ Verificar deployment

### 3. Terraform Deploy (`terraform-deploy.yml`)
Gestiona la infraestructura como código.

**Trigger:**
- Push a `main` con cambios en `/terraform/**`
- Pull Request con cambios en `/terraform/**`
- Dispatch manual (plan/apply/destroy)

**Proceso:**
1. **Format:** Validar formato Terraform
2. **Validate:** Validar sintaxis
3. **Plan:** Generar plan de cambios
4. **Apply:** Aplicar cambios (solo en main o manual)
5. **Destroy:** Destruir infraestructura (solo manual)

---

## 🔐 Configuración de Secretos

### Secretos Requeridos en GitHub

Ve a **Settings → Secrets and variables → Actions** y añade:

| Secreto | Descripción | Ejemplo |
|---------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key con permisos | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key | `wJal...` |
| `GH_TOKEN_AMPLIFY` | GitHub Personal Access Token | `ghp_...` |

### Permisos AWS Necesarios

La cuenta AWS debe tener permisos para:
- ✅ Lambda (crear/actualizar funciones)
- ✅ Amplify (gestionar apps)
- ✅ DynamoDB (gestionar tablas)
- ✅ API Gateway (gestionar APIs)
- ✅ Route53 (gestionar DNS)
- ✅ ACM (gestionar certificados)
- ✅ IAM (crear roles)
- ✅ CloudWatch (logs)

### Crear GitHub Personal Access Token

1. Ve a GitHub → **Settings → Developer settings → Personal access tokens → Tokens (classic)**
2. Click **Generate new token (classic)**
3. Nombre: `Amplify Access Token`
4. Selecciona scopes:
   - ✅ `repo` (Full control of private repositories)
5. Generar y copiar el token
6. Añadirlo como secreto `GH_TOKEN_AMPLIFY`

---

## 🎯 Uso de los Workflows

### Deployment Automático

Los workflows se activan automáticamente al hacer push a `main`:

```bash
# Cambios en frontend
git add curriculum/
git commit -m "Update CV content"
git push origin main
# → Activa frontend-deploy.yml

# Cambios en backend
git add lambda/
git commit -m "Fix Lambda handler"
git push origin main
# → Activa backend-deploy.yml (con tests)

# Cambios en infraestructura
git add terraform/
git commit -m "Update DynamoDB config"
git push origin main
# → Activa terraform-deploy.yml (plan + apply)
```

### Deployment Manual

#### Desde GitHub UI:
1. Ve a **Actions**
2. Selecciona el workflow
3. Click **Run workflow**
4. Elige la rama y opciones
5. Click **Run workflow**

#### Terraform Manual Actions:
- **Plan:** Ver cambios sin aplicar
- **Apply:** Aplicar cambios manualmente
- **Destroy:** ⚠️ Destruir toda la infraestructura

---

## 🧪 Testing Local

### Tests de Lambda

```bash
cd lambda

# Instalar dependencias de test
pip install -r tests/requirements-test.txt

# Ejecutar todos los tests
pytest tests/ -v

# Tests con coverage
pytest tests/ -v --cov=visit_counter --cov-report=html

# Ver reporte de coverage
open htmlcov/index.html
```

### Validar Terraform

```bash
cd terraform

# Formatear código
terraform fmt -recursive

# Validar sintaxis
terraform init -backend=false
terraform validate

# Ver plan
terraform plan -var="github_token=YOUR_TOKEN"
```

---

## 📊 Monitoreo de Workflows

### Ver Estado de Workflows

```bash
# Desde GitHub CLI
gh run list

# Ver detalles de un run
gh run view <run-id>

# Ver logs
gh run view <run-id> --log
```

### Badges en README

Los badges al principio del README.md muestran el estado de cada workflow:
- 🟢 Verde: Todo OK
- 🔴 Rojo: Falló
- 🟡 Amarillo: En progreso

---

## 🔧 Troubleshooting

### Error: "Resource not found"

**Problema:** Lambda/Amplify no existe
**Solución:** Ejecutar primero Terraform para crear la infraestructura

```bash
cd terraform
terraform init
terraform apply -var="github_token=YOUR_TOKEN"
```

### Error: "Access Denied"

**Problema:** Credenciales AWS incorrectas o sin permisos
**Solución:**
1. Verificar secretos en GitHub
2. Verificar permisos IAM en AWS
3. Regenerar Access Keys si es necesario

### Error: "Tests Failed"

**Problema:** Tests de Lambda fallando
**Solución:**
1. Ejecutar tests localmente: `pytest tests/ -v`
2. Corregir errores
3. Push de nuevo

### Error: "Terraform Plan Failed"

**Problema:** Error en configuración Terraform
**Solución:**
1. Validar localmente: `terraform validate`
2. Revisar logs del workflow
3. Corregir configuración

---

## 📝 Best Practices

### Commits

```bash
# ✅ Buenos commits
git commit -m "feat: Add new skill section to CV"
git commit -m "fix: Correct visitor counter display"
git commit -m "chore: Update Lambda memory to 256MB"

# ❌ Evitar
git commit -m "changes"
git commit -m "fix"
```

### Pull Requests

1. Crear rama para cambios:
   ```bash
   git checkout -b feature/new-section
   ```

2. Hacer cambios y commit

3. Push y crear PR:
   ```bash
   git push origin feature/new-section
   ```

4. Los workflows de test se ejecutan automáticamente

5. Merge a main tras aprobar PR

### Rollback

Si algo falla en producción:

```bash
# Ver commits recientes
git log --oneline -5

# Revertir a commit anterior
git revert <commit-hash>
git push origin main
```

---

## 🎓 Referencias

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [AWS Lambda Deployment](https://docs.aws.amazon.com/lambda/latest/dg/lambda-deploy-functions.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Amplify Hosting](https://docs.aws.amazon.com/amplify/latest/userguide/welcome.html)

---

**Última actualización:** 8 de enero de 2026
