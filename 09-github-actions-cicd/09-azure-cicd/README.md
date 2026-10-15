# Ejercicio 09 — Azure: GitHub Actions + Terraform Cloud

## Objetivo

Construir un flujo de CI/CD de infraestructura para Azure usando GitHub Actions para validaciones y HCP Terraform para plan, state remoto y apply. En este ejercicio inicial **no se usa autenticación federada**.

## Arquitectura del flujo

`Pull Request → GitHub Actions (fmt/checks) → HCP Terraform speculative plan → merge a main → HCP Terraform plan → aprobación manual → apply`

## 1. Prerrequisitos

- Suscripción Azure de laboratorio.
- Cuenta HCP Terraform con una organización.
- Conexión VCS de GitHub habilitada en HCP Terraform.
- Permisos para crear un Resource Group y una Storage Account.

## 2. Configurar credenciales Azure en HCP Terraform

Crea un Service Principal dedicado al laboratorio. En una terminal autenticada con Azure CLI:

```bash
az login
az account set --subscription "<SUBSCRIPTION_ID>"
az ad sp create-for-rbac \
  --name "sp-tfc-azure-lab" \
  --role Contributor \
  --scopes "/subscriptions/<SUBSCRIPTION_ID>"
```

Copia los valores de `appId`, `password`, `tenant` y tu subscription ID. No los guardes en Git.

En el workspace de HCP Terraform, abre **Variables** y configura como variables de entorno sensibles:
- `ARM_CLIENT_ID` = valor de `appId`
- `ARM_CLIENT_SECRET` = valor de `password` (**sensitive**)
- `ARM_TENANT_ID` = valor de `tenant`
- `ARM_SUBSCRIPTION_ID` = ID de suscripción

No uses auto-apply para este laboratorio. El rol Contributor a nivel de suscripción es amplio; usa una suscripción de laboratorio y revoca el acceso al terminar. En entornos reales, limita el scope.

## 3. Crear el workspace VCS-driven

En HCP Terraform:
1. Crea un workspace llamado `gha-azure-cicd`.
2. Selecciona el workflow basado en **Version Control**.
3. Conecta el repositorio `aldo2510/terraform-exercises`.
4. Selecciona la rama `main`.
5. Configura **Terraform Working Directory** con `09-github-actions-cicd/09-azure-cicd`.
6. Desactiva Auto Apply para revisar cada plan manualmente.
7. En Variables, añade una variable Terraform `location` con valor `eastus` si quieres modificar la región predeterminada.

El workspace remoto recibirá el state y ejecutará plan/apply cuando se actualice el código.

## 4. Configurar GitHub Actions

El archivo `.github/workflows/azure-terraform.yml` corre únicamente en cambios en la carpeta de este ejercicio. Para esta sesión, GitHub Actions se encarga de calidad básica de código; la ejecución real de Terraform se realiza desde el workspace de HCP Terraform conectado por VCS.

En este repositorio, el workflow puede ejecutarse sin credenciales Azure: checkout y `terraform fmt -check`. HCP Terraform mantiene las credenciales cloud y el state fuera del runner.

## 5. Ejecutar el flujo

1. Crea una rama y modifica un tag en `main.tf`.
2. Abre un pull request a `main`.
3. En la pestaña **Actions** revisa que el workflow de validación sea exitoso.
4. En HCP Terraform abre el workspace `gha-azure-cicd`, localiza el speculative plan asociado al pull request y revisa los cambios.
5. Integra el pull request.
6. Abre **Runs** del workspace. Revisa el plan relacionado al commit y pulsa **Confirm & Apply** solamente después de comprobar el plan.
7. Verifica en Azure Portal los recursos.

## 6. Limpiar

Desde el workspace inicia un run de destroy, revisa los recursos que se eliminarán y confirma manualmente. No borres el workspace antes de destruir los recursos.

## Criterios de éxito

- GitHub Actions valida el formato de Terraform.
- HCP Terraform está enlazado al repositorio.
- El working directory apunta a la carpeta correcta.
- Un PR genera un speculative plan.
- Un commit a main crea un run en el workspace.
- Apply requiere aprobación manual y el state permanece remoto.

## Preguntas

1. ¿Qué tarea realiza GitHub Actions y cuál realiza HCP Terraform?
2. ¿Por qué no se guarda el state en GitHub?
3. ¿Qué diferencia hay entre speculative plan y plan normal?
4. ¿Qué cambiaría al implementar OIDC en una sesión posterior?

## Referencias

- [HCP Terraform VCS workflow](https://developer.hashicorp.com/terraform/cloud-docs/run/ui)
- [AzureRM provider: autenticación](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions: workflows](https://docs.github.com/actions/writing-workflows)
