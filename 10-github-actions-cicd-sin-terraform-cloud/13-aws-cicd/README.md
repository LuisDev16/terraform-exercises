# Ejercicio 13 — AWS CI/CD con GitHub Actions y Terraform CLI

Crear un bucket S3 privado con Terraform CLI ejecutado en GitHub Actions. El state se guarda en un bucket S3 remoto independiente. No se usa Terraform Cloud ni OIDC.

## Backend
Crea manualmente un bucket S3 dedicado al state, con bloqueo de acceso público, cifrado y versionado. En GitHub Variables configura `AWS_TFSTATE_BUCKET`, `AWS_TFSTATE_KEY` y `AWS_REGION`. Este bucket no es el recurso que administra el ejercicio.

## Credenciales
En GitHub Secrets configura `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY` de un IAM user dedicado. Limita sus permisos al bucket del ejercicio y al backend de state. No uses AdministratorAccess ni claves de producción.

## Pasos
1. Abre un PR con un cambio en el código y revisa fmt, validate y plan.
2. Integra en main.
3. En Actions → AWS Terraform CLI → Run workflow selecciona apply.
4. Comprueba el bucket en AWS Console.
5. Ejecuta destroy al finalizar.

El backend debe existir antes de `terraform init`. Protege production con required reviewers y no subas credenciales, tfstate ni planes al repo.

Referencia: https://developer.hashicorp.com/terraform/language/backend/s3