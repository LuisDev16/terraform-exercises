# Ejercicio 12 — Azure CI/CD con GitHub Actions y Terraform CLI

El objetivo es desplegar un Resource Group y una Storage Account directamente desde GitHub Actions. El state se guarda en Azure Blob Storage. No se usa Terraform Cloud ni autenticación federada.

## Preparar backend
Crea manualmente un Resource Group dedicado al state, una Storage Account y un container `tfstate`. Debe existir antes de terraform init y ser independiente de los recursos del ejercicio.

## GitHub Secrets
`ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`, `AZURE_CREDENTIALS_JSON` (JSON de login Azure).

## GitHub Variables
`AZURE_STATE_RESOURCE_GROUP`, `AZURE_STATE_STORAGE_ACCOUNT`, `AZURE_STATE_CONTAINER`, `AZURE_STATE_KEY`, `AZURE_LOCATION`.

El Service Principal necesita permisos para administrar los recursos y leer/escribir el state en Blob. Usa una cuenta de laboratorio y alcance mínimo.

## Pasos
1. Modifica un tag en una rama y abre PR.
2. Revisa fmt, validate y plan en Actions.
3. Integra en main.
4. Ejecuta Actions → Azure Terraform CLI → Run workflow → apply.
5. Verifica los recursos en Azure Portal.
6. Ejecuta destroy al terminar.

Protege production con required reviewers. No subas tfstate ni credenciales. El backend no debe borrarse con este ejercicio.

Referencia: https://developer.hashicorp.com/terraform/language/backend/azurerm