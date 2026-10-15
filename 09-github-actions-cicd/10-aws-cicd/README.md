# Ejercicio 10 — AWS: GitHub Actions + Terraform Cloud

## Objetivo

Construir un flujo CI/CD para crear un bucket S3 con seguridad básica. GitHub Actions realiza validaciones y HCP Terraform administra el state, los runs y el apply. **En esta primera versión no se usa autenticación federada.**

## Flujo

`Pull Request → GitHub Actions (fmt/checks) → HCP Terraform speculative plan → merge a main → HCP Terraform plan → aprobación manual → apply`

## 1. Crear credenciales para el laboratorio

En AWS IAM, crea un usuario técnico dedicado al laboratorio y genera una access key para este. No uses credenciales personales o de producción.

En el workspace de HCP Terraform añade variables de entorno sensibles:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_DEFAULT_REGION` = `us-east-1` (o región de laboratorio)

La política del usuario debe limitarse a las operaciones S3 requeridas y al bucket del laboratorio cuando sea posible. Evita `AdministratorAccess`. Las access keys son credenciales de larga duración: guárdalas únicamente en HCP Terraform, no en GitHub, Terraform files ni logs. Revócalas al finalizar.

## 2. Configurar el workspace VCS-driven

1. En HCP Terraform crea el workspace `gha-aws-cicd`.
2. Conecta `aldo2510/terraform-exercises` con la integración VCS.
3. Configura la rama `main`.
4. Establece el working directory como `09-github-actions-cicd/10-aws-cicd`.
5. Desactiva Auto Apply para revisar y confirmar los planes manualmente.

El state se guarda en HCP Terraform. No configures un backend S3 dentro de esta misma carpeta: el workspace remoto controla el state.

## 3. Recursos del ejercicio

Terraform crea un bucket S3 cuyo nombre se basa en prefijo, ID de cuenta y región. Habilita:
- bloqueo total de acceso público,
- versionado,
- cifrado SSE-S3.

El bucket debe estar vacío antes del destroy; no uses esta práctica para almacenar información real.

## 4. Validación mediante GitHub Actions

El workflow `.github/workflows/aws-terraform.yml` ejecuta `terraform fmt -check`, `init -backend=false` y `validate`. No necesita credenciales AWS porque no ejecuta el plan de recursos desde el runner.

## 5. Ejecutar el ciclo CI/CD

1. Abre una rama y modifica un tag o el prefijo.
2. Abre un pull request a `main` y revisa el workflow en **Actions**.
3. En HCP Terraform abre `gha-aws-cicd` y revisa el speculative plan.
4. Integra el cambio.
5. Revisa el plan del run que se inicia en el workspace y confirma manualmente el apply.
6. Comprueba el bucket en AWS Console.

## 6. Destruir recursos

Inicia un run destroy desde HCP Terraform, revisa el plan y confirma manualmente. Si hay objetos o versiones, vacía el bucket de forma controlada primero. Después, revoca/elimina la access key temporal del laboratorio.

## Criterios de éxito

- GitHub Actions valida HCL y formato.
- HCP Terraform se conecta al repositorio y carpeta correctos.
- Los PR generan speculative plan.
- Los commits generan runs en HCP Terraform.
- Apply requiere confirmación manual.
- State remoto sin archivos .tfstate en Git.

## Preguntas

1. ¿Qué diferencia hay entre una access key y OIDC?
2. ¿Qué hace HCP Terraform con el state?
3. ¿Qué valida GitHub Actions antes de llegar al plan?
4. ¿Por qué conviene desactivar Auto Apply en el laboratorio?

## Referencias

- [HCP Terraform VCS workflow](https://developer.hashicorp.com/terraform/cloud-docs/run/ui)
- [AWS provider authentication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions workflows](https://docs.github.com/actions/writing-workflows)
