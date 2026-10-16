# Ejercicio 14 — Google Cloud CI/CD con GitHub Actions y Terraform CLI

Desplegar un bucket privado de Cloud Storage con Terraform CLI desde GitHub Actions. El state remoto se almacena en un bucket GCS independiente. No se usa Terraform Cloud ni Workload Identity Federation.

## Backend
Crea manualmente un bucket GCS dedicado al state, con acceso público prevenido y versionado habilitado. Debe existir antes de `terraform init`. Configura GitHub Variables `GCP_TFSTATE_BUCKET`, `GCP_TFSTATE_PREFIX`, `GCP_PROJECT_ID` y `GCP_REGION`.

## Credenciales
En GitHub Secrets configura `GCP_CREDENTIALS_JSON` con el contenido completo de la clave JSON de un service account de laboratorio. Dale permisos mínimos para el bucket de práctica y el state. No subas el JSON a Git; elimina la clave al finalizar.

## Pasos
1. Abre un PR con un cambio pequeño y revisa fmt, validate y plan.
2. Integra en main.
3. En Actions → Google Cloud Terraform CLI → Run workflow selecciona apply.
4. Verifica el bucket en Google Cloud Console.
5. Ejecuta destroy al finalizar.

Protege production con required reviewers. El backend es independiente y no se elimina con este ejercicio.

Referencia: https://developer.hashicorp.com/terraform/language/backend/gcs