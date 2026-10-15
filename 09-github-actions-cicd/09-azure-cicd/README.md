# Ejercicio 09 — CI/CD en Azure con GitHub Actions y Terraform

## Objetivo

Automatizar el ciclo de infraestructura en Azure usando Terraform y GitHub Actions. Se crea un Resource Group y una Storage Account con controles básicos de seguridad.

## Flujo

`Pull Request → fmt/init/validate/plan → merge a main → workflow_dispatch → apply/destroy`

## 1. Requisitos

- Suscripción Azure activa.
- Azure CLI instalado localmente, para obtener los identificadores y comprobar recursos.
- Permiso para crear Resource Groups y Storage Accounts.
- En el repositorio GitHub, abre **Settings → Secrets and variables → Actions**.

## 2. Crear el Service Principal

Para este laboratorio introductorio se usa un Service Principal con secreto. En una terminal con Azure CLI autenticado como administrador:

```bash
az login
az account set --subscription "<SUBSCRIPTION_ID>"
az ad sp create-for-rbac \
  --name "sp-github-terraform-lab" \
  --role Contributor \
  --scopes "/subscriptions/<SUBSCRIPTION_ID>"
```

Copia del resultado los valores `appId`, `password` y `tenant`. El comando puede imprimir un secreto una sola vez: guárdalo directamente en GitHub y no lo pegues en el repositorio, logs ni capturas.

> El rol Contributor al nivel de suscripción es amplio para facilitar el primer laboratorio. En un entorno real, limita el alcance y los permisos a un resource group dedicado y rota/elimina el secreto al terminar.

## 3. Crear variables y secretos de GitHub

En **Settings → Secrets and variables → Actions**:

**Variables (no confidenciales):**
- `AZURE_SUBSCRIPTION_ID`: ID de suscripción.
- `AZURE_TENANT_ID`: ID del tenant de Entra ID.
- `AZURE_CLIENT_ID`: Application (client) ID del Service Principal.

**Secret (confidencial):**
- `AZURE_CLIENT_SECRET`: valor de `password` generado en el paso anterior.

## 4. Qué crea Terraform

- Resource Group con tags del laboratorio.
- Storage Account Standard/LRS.
- HTTPS obligatorio y TLS mínimo 1.2.
- Acceso público de blobs deshabilitado.
- Versionado de blobs habilitado.

Los nombres se derivan de un prefijo y parte del ID de suscripción para minimizar colisiones.

## 5. Ejecutar CI

Crea una rama, realiza un cambio pequeño y abre un pull request a `main`. El workflow ejecuta:
1. `terraform fmt -check -recursive`
2. `terraform init`
3. `terraform validate`
4. `terraform plan`

No hace `apply` automáticamente en un pull request.

## 6. Desplegar y limpiar

Después de integrar en `main`, ve a **Actions → Azure Terraform → Run workflow** y selecciona `apply`. Revisa la ejecución y verifica el Resource Group en Azure Portal.

Al terminar, repite el workflow seleccionando `destroy`. Revisa el plan de eliminación antes de aprobar/ejecutar.

## 7. Preguntas

- ¿Qué diferencia hay entre una variable y un secreto de GitHub?
- ¿Por qué un plan de pull request no debería aplicar cambios?
- ¿Qué aporta OIDC frente a un secreto de larga duración? (mejora para una siguiente versión)

## Referencias

- [Azure Login action](https://github.com/Azure/login)
- [Terraform AzureRM provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
