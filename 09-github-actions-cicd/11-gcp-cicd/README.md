# Ejercicio 11 — Google Cloud: GitHub Actions + Terraform Cloud

## Objetivo

Crear un bucket de Cloud Storage privado con Terraform. GitHub Actions valida el código y HCP Terraform ejecuta los runs, administra el state remoto y requiere confirmación manual para apply. **En esta versión no se usa autenticación federada.**

## Flujo

`Pull Request → GitHub Actions (fmt/checks) → HCP Terraform speculative plan → merge a main → HCP Terraform plan → aprobación manual → apply`

## 1. Crear un service account para el ejercicio

En Google Cloud Console crea un service account dedicado al laboratorio. Asígnale los permisos mínimos para crear, consultar y eliminar buckets en el proyecto de práctica. Para un proyecto aislado puede usarse temporalmente `roles/storage.admin`, aunque es un rol amplio; no uses Owner ni Editor.

Crea una clave JSON solo si las políticas de la organización permiten este método. Guarda el archivo en un lugar seguro y **no** lo agregues al repositorio.

## 2. Configurar credenciales en HCP Terraform

En el workspace, ve a **Variables** y añade:
- `GOOGLE_CREDENTIALS`: variable de entorno sensible con el contenido completo del JSON.
- `GOOGLE_PROJECT`: ID del proyecto, como variable de entorno o variable Terraform `project_id`.
- `GOOGLE_REGION`: región de laboratorio, si quieres reemplazar el valor predeterminado.

HCP Terraform debe recibir el JSON completo en `GOOGLE_CREDENTIALS`, no una ruta local del archivo. Limita las credenciales al proyecto de laboratorio y revoca/elimina la clave al finalizar. Si tu organización prohíbe claves de service account, detente aquí y sustituye esta sección por Workload Identity Federation en una siguiente versión.

## 3. Crear el workspace VCS-driven

1. En HCP Terraform crea `gha-gcp-cicd`.
2. Conecta el repositorio `aldo2510/terraform-exercises`.
3. Selecciona `main` y define el working directory `09-github-actions-cicd/11-gcp-cicd`.
4. Desactiva Auto Apply para inspeccionar el plan.
5. Comprueba que no se haya configurado un backend GCS dentro del código: HCP Terraform administrará el state remoto.

## 4. Recursos creados

El ejercicio crea un bucket de Cloud Storage con:
- prevención de acceso público,
- uniform bucket-level access,
- versionado,
- etiquetas para identificar la infraestructura de laboratorio.

El nombre del bucket debe ser único globalmente. Usa un proyecto dedicado y revisa siempre el plan.

## 5. CI con GitHub Actions

El workflow `.github/workflows/gcp-terraform.yml` ejecuta `terraform fmt -check`, `terraform init -backend=false` y `terraform validate`. Las credenciales no se necesitan en el runner, ya que HCP Terraform gestiona la ejecución real y la autenticación del provider.

## 6. Completar el ciclo

1. Abre una rama y realiza un cambio pequeño.
2. Crea un pull request hacia `main`.
3. Comprueba el workflow en GitHub Actions y revisa el speculative plan en HCP Terraform.
4. Integra el PR y abre el run generado en el workspace.
5. Inspecciona el plan y pulsa **Confirm & Apply**.
6. Verifica el bucket en Google Cloud Console.

## 7. Limpiar

Ejecuta destroy desde el workspace, revisa el plan y confirma manualmente. Comprueba que el bucket se haya eliminado y elimina la clave de service account usada en este laboratorio.

## Criterios de éxito

- Workflow de GitHub Actions exitoso.
- VCS conectado a la carpeta de este ejercicio.
- PR y commits generan planes/runs en HCP Terraform.
- Apply manual.
- State remoto y fuera del repositorio.

## Preguntas

1. ¿Qué diferencia hay entre un service account y una identidad federada?
2. ¿Por qué es peligroso almacenar la clave JSON en el repo?
3. ¿Qué ventaja tiene que HCP Terraform guarde el state?
4. ¿Qué acciones corresponden a GitHub Actions y cuáles a HCP Terraform?

## Referencias

- [HCP Terraform VCS workflow](https://developer.hashicorp.com/terraform/cloud-docs/run/ui)
- [Google provider authentication](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GitHub Actions workflows](https://docs.github.com/actions/writing-workflows)
