# Sesión 09 — CI/CD de infraestructura con GitHub Actions y Terraform Cloud

Estos tres ejercicios están alineados con el tema **CI/CD de infraestructura usando GitHub Actions y Terraform Cloud**. Cada alumno trabajará un proveedor diferente (Azure, AWS o Google Cloud) y conectará su repositorio con un workspace VCS-driven de HCP Terraform.

## Ejercicios

| Ejercicio | Carpeta | Resultado |
|---|---|---|
| 09 — Azure | [09-azure-cicd](./09-azure-cicd) | GitHub Actions valida el código; HCP Terraform ejecuta plan/apply del workspace de Azure |
| 10 — AWS | [10-aws-cicd](./10-aws-cicd) | GitHub Actions valida el código; HCP Terraform ejecuta plan/apply del workspace de AWS |
| 11 — GCP | [11-gcp-cicd](./11-gcp-cicd) | GitHub Actions valida el código; HCP Terraform ejecuta plan/apply del workspace de Google Cloud |

## Diseño del flujo

1. **GitHub Actions CI:** checkout, `terraform fmt -check` y comprobaciones estáticas de los archivos del proveedor.
2. **VCS-driven workflow:** HCP Terraform está conectado al repositorio y al directorio de trabajo específico del ejercicio.
3. **Plan:** cada commit genera un run en HCP Terraform; el alumno revisa el plan antes de aplicar.
4. **Apply:** se aprueba manualmente desde HCP Terraform. No se activa auto-apply para el laboratorio.
5. **Credenciales cloud:** por ahora se configuran como variables sensibles del workspace de HCP Terraform (o variables de entorno específicas del provider). **No se usa OIDC ni federación de identidad en esta versión.** Esa sería una mejora futura.
6. **State:** lo gestiona HCP Terraform de forma remota; no se sube el archivo de state al repositorio ni se almacena como artefacto del workflow.

## Antes de empezar

- Cuenta de GitHub con Actions habilitado.
- Cuenta y organización de HCP Terraform.
- Acceso para conectar el repositorio mediante VCS.
- Una cuenta/proyecto/subscripción cloud de laboratorio.
- Terraform CLI actualizado localmente para seguir los comandos opcionales.
- Lee el README del proveedor que te corresponde y sigue los pasos en el orden indicado.

> **Costos y seguridad:** los recursos descritos son reales cuando se aprueba el apply. Utiliza cuentas de laboratorio, revisa el plan y ejecuta destroy al finalizar. No uses cuentas de producción ni guardes secretos, archivos de estado o claves JSON en Git.

## Dinámica de clase

1. Preparar el proveedor y las credenciales en HCP Terraform.
2. Crear un workspace de tipo VCS-driven.
3. Configurar el working directory y la rama de seguimiento.
4. Agregar el workflow de GitHub Actions.
5. Abrir un pull request y revisar las validaciones / speculative plan.
6. Integrar el cambio, revisar el run y aprobar el apply.
7. Cambiar un tag, repetir el flujo y revisar la diferencia del plan.
8. Ejecutar destroy al finalizar.
