# Sesión 09 — CI/CD multicloud con GitHub Actions y Terraform

Tres laboratorios independientes para implementar infraestructura como código con GitHub Actions. Cada proveedor mantiene su propio directorio, workflow y guía de configuración de credenciales.

## Laboratorios

| Ejercicio | Carpeta | Infraestructura |
|---|---|---|
| Azure | [09-azure-cicd](./09-azure-cicd) | Resource Group + Storage Account |
| AWS | [10-aws-cicd](./10-aws-cicd) | S3 privado con versionado y cifrado |
| Google Cloud | [11-gcp-cicd](./11-gcp-cicd) | Bucket de Cloud Storage privado |

## Flujo común

- **Pull request:** `terraform fmt -check`, `init`, `validate` y `plan`.
- **Push a main:** vuelve a validar y genera el plan.
- **Despliegue:** ejecución manual (`workflow_dispatch`) para hacer `apply` o `destroy`.
- **Credenciales:** por ahora se utilizan secretos de GitHub para las credenciales/identificadores de autenticación tradicionales de cada proveedor. La autenticación federada queda como mejora posterior del laboratorio.
- **Protección recomendada:** configura un environment `production` con revisores requeridos para proteger el despliegue.

> Los workflows pueden crear recursos reales y generar costos. Revisa el plan antes de aplicar y destruye los recursos al terminar. No utilices cuentas de producción ni guardes credenciales en archivos Terraform.

## Requisitos generales

- GitHub Actions habilitado en el repositorio.
- Permisos para crear los recursos descritos en cada proveedor cloud.
- Configurar las variables/secretos descritos en el README de cada ejercicio.
- Para equipos, sustituye el state local del runner por un backend remoto con control de acceso y locking.

## Dinámica sugerida

1. Completar las credenciales.
2. Crear una rama y abrir un pull request.
3. Revisar la validación y el plan en Actions.
4. Integrar el cambio a `main`.
5. Ejecutar manualmente `apply` y verificar el recurso.
6. Ejecutar manualmente `destroy` y confirmar la limpieza.
