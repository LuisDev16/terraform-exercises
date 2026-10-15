# Ejercicio 11 — CI/CD en Google Cloud con GitHub Actions y Terraform

## Objetivo

Crear un bucket privado de Cloud Storage usando Terraform y GitHub Actions. En esta primera versión se utilizan credenciales de service account almacenadas en GitHub Secrets. En una siguiente versión se puede migrar a Workload Identity Federation.

## 1. Requisitos

- Proyecto de Google Cloud con facturación habilitada.
- APIs de Cloud Storage y IAM habilitadas.
- Permisos para crear un service account y asignarle roles.
- Un service account dedicado al laboratorio.

## 2. Crear service account y clave JSON

En Google Cloud Console → IAM & Admin → Service Accounts, crea por ejemplo `github-terraform-lab`.

Concede los permisos necesarios para crear, consultar y eliminar buckets de Cloud Storage en el proyecto de laboratorio. `Storage Admin` (`roles/storage.admin`) es un rol amplio, así que úsalo solo en un proyecto aislado para esta práctica; no concedas Owner ni Editor al service account.

Crea una clave JSON para el service account. Descárgala y guárdala temporalmente en un lugar seguro. No la subas al repositorio.

En GitHub → Settings → Secrets and variables → Actions → Secrets configura:
- `GCP_CREDENTIALS_JSON`: pega el contenido completo del JSON de la clave, incluyendo llaves y comillas.

En Variables configura:
- `GCP_PROJECT_ID`: ID del proyecto.
- `GCP_REGION`: por ejemplo `us-central1`.

> Las claves JSON son credenciales de larga duración. Limita la clave a este laboratorio, no la compartas con alumnos y elimínala al finalizar. Si la política de la organización prohíbe claves de service account, no uses esta variante: implementa Workload Identity Federation.

## 3. Qué crea Terraform

Un bucket de Cloud Storage con:
- acceso público prevenido,
- uniform bucket-level access,
- versionado de objetos,
- etiqueta que indica que lo administra Terraform.

El nombre incorpora el ID del proyecto y un prefijo configurable.

## 4. Ejecutar CI

Abre un pull request modificando una variable o tag. GitHub Actions ejecuta `terraform fmt -check`, `init`, `validate` y `plan`; no hace apply automáticamente.

## 5. Desplegar y destruir

Después de integrar en `main`, abre **Actions → GCP Terraform → Run workflow** y elige `apply` o `destroy`. Configura el environment `production` con required reviewers para añadir una aprobación manual.

Verifica el bucket desde Google Cloud Console → Cloud Storage. Al finalizar, ejecuta `destroy` y confirma que el bucket fue eliminado.

## Preguntas

- ¿Dónde se debe guardar una clave privada?
- ¿Por qué un service account no debería tener Owner?
- ¿Qué riesgos tiene guardar claves JSON de larga duración?
- ¿Cómo se migraría a Workload Identity Federation?

## Referencias

- [Google GitHub Actions Auth](https://github.com/google-github-actions/auth)
- [Google provider para Terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
