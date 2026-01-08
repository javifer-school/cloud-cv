# Propuesta de Infraestructura AWS - Curriculum ITIC

## 📋 Información del Desafío

**Reto:** Cloud Resume Challenge - AWS Edition  
**Referencia:** https://cloudresumechallenge.dev/docs/the-challenge/aws/

**Duración:** 6 horas de clase - 3 sesiones  
**Presentación y defensa:** lunes 12 de enero (5 minutos)

---

## 📌 Requisitos Importantes

### Documentación del Progreso
- ✅ **Google Docs**: Documentar el progreso con historial visible
- ✅ **PDF diario**: Publicar PDF completo cada día

---

## 🎯 Objetivos del Desafío

Mostrar tu currículum online en AWS completando los siguientes puntos:

| # | Componente | Estado |
|---|-----------|--------|
| ~~1~~ | ~~Certification~~ | (Opcional) |
| 2 | HTML | ⬜ |
| 3 | CSS | ⬜ |
| 4 | Static Website | ⬜ |
| 5 | HTTPS | ⬜ |
| 6 | DNS | ⬜ |
| 7 | Javascript | ⬜ |
| 8 | Database | ⬜ |
| 9 | API | ⬜ |
| 10 | Python | ⬜ |
| 11 | Tests | ⬜ |
| 12 | Infrastructure as Code | ⬜ |
| 13 | Source Control | ⬜ |
| 14 | CI/CD (Back end) | ⬜ |
| 15 | CI/CD (Front end) | ⬜ |
| ~~16~~ | ~~Blog post~~ | (Opcional) |

---

## 🏗️ Propuesta de Infraestructura en AWS

### **Front-end (Puntos 2, 3, 4, 5, 7, 13)**

**Tecnologías:**
- 📝 **Generador CV**: Hugo/Jekyll (+++) o IA (+)
- 🎨 **Plantilla**: Similar a CareerCanvas o felipecordero.com (sin datos personales, foto = dibujo)
- 🔗 **Repositorio**: GitHub (generador + CV generado)
- 📦 **Hosting**: AWS Amplify

**Requisitos:**
- HTML/CSS profesional
- JavaScript para interactividad
- HTTPS habilitado
- Versionado en GitHub

---

### **DNS y Dominio (Puntos 5, 6)**

**Infraestructura:**
- 🔐 **HTTPS**: Certificado para el dominio (AWS ACM o proveedor)
- 🌐 **Route53**: Subdominio `cv.aws10.xxxxx.cat`

---

### **Back-end (Puntos 8, 9, 10, 11, 14)**

**Arquitectura:**
```
DynamoDB → Lambda → API Gateway
   ↓
  [Python]
   ↓
 [Tests]
   ↓
 [CI/CD]
```

**Componentes:**

1. **Base de Datos (Punto 8)**
   - 🗄️ DynamoDB
   - 💾 Backup automático
   - 🚀 Extensión: Múltiples currículums

2. **API (Punto 9)**
   - 🔌 API Gateway
   - 📡 Endpoints RESTful

3. **Lógica de Negocio (Punto 10)**
   - 🐍 Lambda (Python)

4. **Tests (Punto 11)**
   - ✅ Unit tests Python
   - CI/CD para validación

5. **CI/CD Backend (Punto 14)**
   - GitHub Actions
   - Deploy automático en push

---

### **Infrastructure as Code (Punto 12)**

**Terraform Configuration:**
```hcl
// Infraestructura a desplegar:
- Amplify (4): Static website hosting
- ACM (5): HTTPS certificate
- Route53 (6): DNS management
- DynamoDB (8): Database
- API Gateway (9): API endpoints
- Lambda (10): Serverless functions
```

**Características:**
- ✅ Configuración modular
- ✅ State S3 versionado con lock
- ✅ GitHub Actions: Deploy automático en push
- ℹ️ Avanzado: Sin DynamoDB para el estado (S3 versionado)

---

### **CI/CD Front-end (Punto 15)**

**Requisitos:**
- GitHub Actions workflow
- Deploy automático en push a `main`
- Testing de plantilla (Hugo/Jekyll)

---

### **Git & Versionado (Punto 13)**

**Estructura:**
```
/curriculum/          ← Generador + Plantilla
/terraform/           ← Infrastructure as Code
/.github/workflows/   ← CI/CD pipelines
```

---

## 🛠️ Stack Tecnológico Propuesto

| Componente | Tecnología | Plataforma |
|-----------|-----------|-----------|
| Generador CV | Hugo / Jekyll | GitHub |
| Hosting Front | Amplify | AWS |
| DNS | Route53 | AWS |
| HTTPS | ACM | AWS |
| Database | DynamoDB | AWS |
| Backend API | API Gateway + Lambda | AWS |
| Lenguaje Backend | Python | AWS Lambda |
| IaC | Terraform | Local / GitHub Actions |
| Versionado | Git | GitHub |
| CI/CD | GitHub Actions | GitHub |

---

## 📚 Recursos de Ayuda

### API/DynamoDB/Lambda
- 🎓 AWS SkillBuilder: [API with Database](https://skillbuilder.aws/learn/J76QXZJBXA/aws-simulearn-api-with-database/6APQE2E9RA)

### Cloudflare (si se utiliza)
**Variables de entorno:**
```bash
# En ~/.bashrc o ~/.zshrc (sin historial: añade espacio al inicio)
 export CF_API_TOKEN="tu_token_aqui"
 export CLOUDFLARE_API_TOKEN=$CF_API_TOKEN
```

### Windows + Linux
- 📖 WSL Documentation: [Instalar WSL en Windows](https://learn.microsoft.com/es-es/windows/wsl/install)

---

## 💰 Mejoras Adicionales

### Estimación de Costos
- 📊 [AWS Pricing Calculator](https://calculator.aws/)

### Propuestas de Extensión
Una vez completada la parte básica, se aceptan propuestas como:
- ✨ Dashboard de métricas
- 🔐 Autenticación avanzada
- 📊 Analytics
- 🌍 Multi-región
- etc.

---

## 📅 Timeline

| Fase | Fecha | Duración |
|------|-------|----------|
| **Clase 1** | Semana 1 | 2h |
| **Clase 2** | Semana 1-2 | 2h |
| **Clase 3** | Semana 2 | 2h |
| **Presentación** | Lunes 12 Enero | 5 min |

---

## ✅ Checklist de Entrega

- [ ] Google Doc con progreso diario
- [ ] PDF completo actualizado diariamente
- [ ] Repositorio GitHub con código fuente
- [ ] Terraform code para IaC
- [ ] Curriculum online funcional en AWS
- [ ] Presentación preparada (5 min)

---

## 📞 Notas Finales

- ⚠️ **MUY IMPORTANTE**: Mantener documentación y PDF actualizados
- 💡 **Tips**: Revisar plantillas de Hugo/Jekyll previo a implementación
- 🔗 **Referencias**: Usar ejemplos profesionales como guía
- 🎯 **Enfoque**: Completar primero los 13 puntos básicos, luego mejoras

---

**Última actualización:** 8 de enero de 2026  
**Estado:** 🟡 En preparación
