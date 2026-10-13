# Terraform Exercises — AWS, Azure & Multicloud

Repositorio de ejercicios prácticos de Terraform para clases one-to-one.

La ruta va desde fundamentos de Terraform hasta arquitecturas funcionales. No se utilizan máquinas virtuales ni Kubernetes; se priorizan servicios administrados y laboratorios que puedan destruirse al finalizar.

## Estructura de arquitecturas

06-architectures/
- 01-storage-observability/ — AWS: S3 + CloudWatch
- 02-file-processing/ — AWS: S3 + Lambda + CloudWatch Logs
- 03-static-web/ — Azure: Storage Static Website
- 04-serverless-api/ — Azure: HTTP Function
- 05-async-processing/ — Multicloud: SQS + Azure Storage Queue
- 06-serverless-data/ — Multicloud: DynamoDB + Azure Table Storage

Cada arquitectura incluye README paso a paso y archivos Terraform de solución.

## Dinámica de clase

1. Explicar el patrón arquitectónico.
2. Dibujar el flujo.
3. Identificar los componentes.
4. Pedir al alumno que proponga los recursos Terraform.
5. Implementar sin mirar la solución.
6. Ejecutar terraform fmt.
7. Ejecutar terraform validate.
8. Revisar terraform plan.
9. Aplicar.
10. Probar la arquitectura.
11. Comparar con la solución.
12. Ejecutar terraform destroy.

## Multicloud

Los laboratorios multicloud implementan el mismo patrón lógico en AWS y Azure. No se crea una integración artificial entre ambos proveedores: el objetivo es comparar cómo Terraform expresa una misma capacidad con diferentes providers y recursos.

## Costos

No utilizar VMs no significa costo cero. Revisar pricing/free tier vigente antes de aplicar y destruir los recursos al terminar.

## Sesión 04 — Colaboración con Terraform Cloud

Cinco laboratorios progresivos de HCP Terraform: workspace y Remote State, migración del state local, workflow basado en VCS con GitHub, variables seguras por entorno y Run Triggers entre workspaces.

➡️ [Ver los ejercicios de la sesión 04](08-terraform-cloud/README.md)
