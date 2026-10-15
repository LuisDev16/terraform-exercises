# Ejercicio 10 — CI/CD en AWS con GitHub Actions y Terraform

## Objetivo

Crear un bucket S3 privado usando Terraform y GitHub Actions. En esta primera versión se utiliza un IAM User con access key guardada como secreto de GitHub. La autenticación OIDC se puede implementar en un siguiente ejercicio.

## 1. Requisitos

- Cuenta AWS de laboratorio con permisos para crear y administrar S3.
- AWS CLI para comprobar la identidad y los recursos.
- Un usuario IAM dedicado exclusivamente al laboratorio.

## 2. Crear credenciales IAM

En AWS Console → IAM → Users, crea un usuario dedicado al laboratorio y genera una access key para uso programático. No reutilices credenciales personales ni de producción.

Asigna únicamente permisos necesarios para crear, consultar, configurar y eliminar el bucket del laboratorio. Evita `AdministratorAccess`; la política exacta debe incluir acciones de S3 requeridas por Terraform y limitar recursos siempre que sea posible.

En GitHub → Settings → Secrets and variables → Actions → Secrets configura:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

En Variables configura:
- `AWS_REGION`, por ejemplo `us-east-1`.

Nunca escribas las credenciales en archivos, commits, outputs ni logs. Rota y elimina la access key cuando termines el curso.

## 3. Qué crea Terraform

Un bucket S3 con nombre que combina prefijo, ID de cuenta y región, junto con:
- bloqueo completo de acceso público,
- versionado,
- cifrado SSE-S3.

El ejercicio no carga archivos de usuario.

## 4. CI por pull request

Abre un pull request con una modificación de tags o variables. GitHub Actions ejecuta `fmt -check`, `init`, `validate` y `plan`. No se aplican cambios automáticamente al pull request.

## 5. Desplegar

Integra el cambio en `main`, entra a **Actions → AWS Terraform → Run workflow** y selecciona `apply`. El job utiliza el environment `production`; puedes protegerlo con required reviewers desde Settings → Environments.

## 6. Limpiar

Lanza el mismo workflow con la operación `destroy`. Si el bucket contiene objetos o versiones, deberá vaciarse de forma controlada antes de que Terraform pueda eliminarlo. Verifica en AWS Console que el recurso ya no exista.

## Preguntas

- ¿Por qué las claves se guardan como GitHub Secrets?
- ¿Qué diferencia hay entre access key y un rol IAM?
- ¿Qué riesgo tiene una clave de larga duración?
- ¿Cómo se podría reemplazar por OIDC?

## Referencias

- [AWS credentials action](https://github.com/aws-actions/configure-aws-credentials)
- [AWS provider para Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
