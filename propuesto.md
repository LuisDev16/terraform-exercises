# 🚀 Reto práctico: Infraestructura como Código Multi-Cloud con Terraform y GitHub Actions

## 1. Objetivo

Diseñar e implementar una solución de **Infrastructure as Code (IaC)** que permita aprovisionar infraestructura en AWS, Microsoft Azure y Google Cloud Platform (GCP), utilizando módulos reutilizables de Terraform y pipelines de GitHub Actions.

El objetivo es aplicar buenas prácticas de modularidad, automatización, seguridad y reutilización de componentes para construir una solución similar a la que utilizaría un equipo de Platform Engineering en una organización.

## 2. Escenario

Una organización trabaja con múltiples proveedores cloud y necesita estandarizar la creación de infraestructura. Actualmente, los equipos crean recursos manualmente o mantienen configuraciones duplicadas, lo que genera inconsistencias y dificulta el mantenimiento.

Como equipo de DevOps, deberán crear un repositorio de módulos Terraform reutilizables para cada proveedor cloud y un pipeline de GitHub Actions que permita desplegar infraestructura consumiendo dichos módulos.

## 3. Arquitectura propuesta

La solución deberá organizarse en dos componentes principales:

1. **Repositorio de módulos:** contendrá los módulos Terraform reutilizables para AWS, Azure y GCP.
2. **Repositorio de despliegue:** contendrá las configuraciones que consumirán los módulos y los workflows de GitHub Actions para validar y desplegar la infraestructura.

Cada módulo deberá poder utilizarse desde diferentes proyectos sin necesidad de modificar su implementación interna.

## 4. Actividad 1: Crear módulos Terraform

Deberán implementar al menos un módulo funcional por cada proveedor cloud.

### AWS

Crear un módulo Terraform para aprovisionar:

- Una VPC.
- Una subnet.
- Un security group con reglas mínimas necesarias.
- Una instancia EC2 de tamaño pequeño, si el presupuesto y las cuotas lo permiten.

**Requisitos:**
- Definir variables de entrada y valores por defecto cuando corresponda.
- Exponer outputs relevantes, como el ID de la VPC, la subnet y la instancia.
- Utilizar etiquetas (`tags`) para identificar y administrar los recursos.
- Evitar la exposición de credenciales o secretos en el código.

### Microsoft Azure

Crear un módulo Terraform para aprovisionar:

- Un Resource Group.
- Una Virtual Network (VNet).
- Una subnet.
- Una Network Security Group (NSG).
- Opcionalmente, una máquina virtual pequeña, si el presupuesto y las cuotas lo permiten.

**Requisitos:**
- Parametrizar la ubicación y los nombres de los recursos.
- Definir variables y outputs.
- Aplicar etiquetas a los recursos que las soporten.
- Configurar las reglas de red siguiendo el principio de mínimo privilegio.

### Google Cloud Platform (GCP)

Crear un módulo Terraform para aprovisionar:

- Una VPC.
- Una subnet.
- Reglas de firewall necesarias para el escenario.
- Opcionalmente, una instancia de Compute Engine pequeña, si el presupuesto y las cuotas lo permiten.

**Requisitos:**
- Parametrizar el proyecto, la región y los nombres.
- Definir variables y outputs.
- Aplicar convenciones de nombres consistentes.
- Utilizar autenticación segura desde el pipeline.

> **Importante:** la infraestructura de cada proveedor debe ser independiente. No es necesario desplegar los tres clouds en una misma ejecución.

## 5. Actividad 2: Diseñar el repositorio de módulos

Organic en un repositorio los módulos creados para cada proveedor cloud.

La estructura propuesta es la siguiente:

```text
terraform-modules/
├── aws/
│   └── network/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
├── azure/
│   └── network/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
├── gcp/
│   └── network/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
└── README.md
```

Cada módulo deberá incluir:

- Descripción de su propósito.
- Requisitos y versiones de Terraform y del provider.
- Variables de entrada documentadas.
- Outputs disponibles.
- Ejemplo de uso.
- Instrucciones para validar el módulo.

Los módulos deben tener una interfaz clara y ser reutilizables. No deberán contener credenciales ni valores específicos de un usuario.

## 6. Actividad 3: Consumir los módulos desde otro repositorio

Crear un segundo repositorio que represente un proyecto consumidor de los módulos.

El repositorio deberá contener las configuraciones necesarias para seleccionar el proveedor cloud y desplegar la infraestructura mediante los módulos desarrollados.

Ejemplo de estructura:

```text
terraform-deployment/
├── environments/
│   ├── aws/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars.example
│   ├── azure/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars.example
│   └── gcp/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars.example
├── .github/
│   └── workflows/
│       └── terraform.yml
└── README.md
```

Para consumir los módulos, deberán utilizar referencias al repositorio Git, preferentemente fijadas a un tag o una versión específica.

Ejemplo ilustrativo:

```hcl
module "network" {
  source = "git::https://github.com/ORG/terraform-modules.git//aws/network?ref=v1.0.0"

  name   = "dev-network"
  region = var.region
}
```

Adapten las variables y los argumentos al módulo que hayan implementado. El ejemplo anterior no representa una configuración completa.

## 7. Actividad 4: Crear el pipeline de GitHub Actions

Implementar un workflow que automatice el ciclo de vida de Terraform.

El pipeline deberá contemplar las siguientes etapas:

1. **Validación del código**
   - Verificar el formato con `terraform fmt -check`.
   - Inicializar Terraform.
   - Validar la configuración con `terraform validate`.

2. **Planificación**
   - Ejecutar `terraform plan`.
   - Generar un plan para revisar los cambios que se aplicarían.
   - Publicar o conservar el resultado para su revisión, evitando exponer información sensible.

3. **Aprobación**
   - Incorporar una aprobación manual antes de aplicar los cambios en entornos protegidos.
   - Utilizar GitHub Environments cuando corresponda.

4. **Despliegue**
   - Ejecutar `terraform apply` únicamente después de las validaciones y aprobaciones requeridas.
   - Utilizar el plan revisado y aprobado, sin generar silenciosamente uno distinto.

5. **Limpieza**
   - Permitir la destrucción controlada de la infraestructura de laboratorio mediante una ejecución explícita.
   - Evitar que un `push` o un `pull_request` pueda destruir recursos accidentalmente.

El workflow deberá permitir seleccionar el proveedor cloud mediante una entrada manual, por ejemplo, `workflow_dispatch`, o utilizar workflows independientes para cada proveedor.

### Autenticación y seguridad

- No almacenar credenciales cloud directamente en el repositorio.
- Preferir federación de identidad mediante OIDC cuando el proveedor y la configuración lo permitan.
- Configurar permisos mínimos para el `GITHUB_TOKEN` y las identidades cloud.
- Gestionar los secretos y las variables mediante mecanismos seguros.
- No ejecutar despliegues con privilegios elevados desde pull requests no confiables.
- Utilizar un backend remoto de Terraform cuando esté disponible y configurarlo con controles de acceso y bloqueo de estado adecuados.

## 8. Actividad 5: Validación y demostración

Cada equipo deberá demostrar que su solución funciona de extremo a extremo.

Como mínimo, deberán:

- Ejecutar las validaciones de Terraform.
- Mostrar el consumo de un módulo desde el repositorio de despliegue.
- Ejecutar el pipeline de GitHub Actions.
- Mostrar el resultado del `terraform plan`.
- Aprovisionar infraestructura en al menos un proveedor cloud.
- Demostrar cómo se selecciona otro proveedor para realizar un despliegue independiente.
- Documentar cómo se destruye la infraestructura creada.

**No es obligatorio mantener infraestructura activa en los tres proveedores simultáneamente.** Se valorará la implementación funcional, el control de costos y la correcta separación entre módulos y despliegues.

## 9. Entregables

Cada equipo deberá presentar:

1. URL del repositorio de módulos Terraform.
2. URL del repositorio consumidor.
3. Módulos funcionales para AWS, Azure y GCP.
4. Workflow de GitHub Actions operativo.
5. Evidencias de ejecución de las validaciones, el plan y el despliegue.
6. Documentación de instalación, configuración y uso.
7. Diagrama sencillo de la arquitectura de la solución.
8. Breve explicación de las decisiones tomadas y de los principales problemas encontrados.

## 10. Criterios de evaluación

| Criterio | Puntaje |
|---|---:|
| Modularidad y reutilización de Terraform | 25 puntos |
| Implementación de módulos para AWS, Azure y GCP | 20 puntos |
| Automatización con GitHub Actions | 25 puntos |
| Seguridad y buenas prácticas de IaC | 15 puntos |
| Documentación y demostración técnica | 15 puntos |
| **Total** | **100 puntos** |

## 11. Restricciones y buenas prácticas

- Utilizar Terraform como herramienta de Infrastructure as Code.
- No duplicar innecesariamente configuraciones entre los módulos.
- No incluir credenciales, claves privadas ni archivos de estado en Git.
- No utilizar recursos costosos sin autorización.
- Mantener los permisos de red y de identidad al mínimo necesario.
- Destruir los recursos temporales al finalizar el laboratorio.
- Documentar los requisitos previos, los costos potenciales y las limitaciones encontradas.

## 12. Preguntas para la sustentación

Durante la presentación, cada equipo deberá responder:

1. ¿Qué ventajas ofrece un módulo Terraform frente a copiar y pegar archivos `.tf`?
2. ¿Cómo se puede publicar una nueva versión de un módulo sin afectar a los consumidores existentes?
3. ¿Qué diferencias encontraron al diseñar módulos para AWS, Azure y GCP?
4. ¿Por qué es importante separar el repositorio de módulos del repositorio consumidor?
5. ¿Qué diferencia existe entre `terraform plan` y `terraform apply`?
6. ¿Cómo garantizarían que una infraestructura no se despliegue sin aprobación?
7. ¿Qué riesgos existen si varios pipelines modifican el mismo estado de Terraform?
8. ¿Cómo gestionarían las credenciales cloud sin almacenarlas en GitHub?
9. ¿Cómo incorporarían controles de seguridad y políticas de cumplimiento en el pipeline?
10. ¿Cómo escalarían esta solución para que distintos equipos de desarrollo puedan consumir los módulos de forma estandarizada?

## 13. Desafío adicional (opcional)

Para los equipos que quieran profundizar, implementar una o más de las siguientes mejoras:

- Incorporar análisis estático con `TFLint`, Checkov o Trivy.
- Incorporar políticas como código con Open Policy Agent (OPA) y Rego.
- Publicar versiones semánticas de los módulos.
- Implementar workflows reutilizables de GitHub Actions.
- Separar los entornos de desarrollo, pruebas y producción.
- Incorporar detección de costos estimados antes del despliegue.
- Configurar despliegues con identidades federadas y permisos mínimos.
- Generar documentación automática de los módulos.

## Resultado esperado

Al finalizar el reto, cada equipo deberá contar con una solución reutilizable de Terraform para tres proveedores cloud y un pipeline de GitHub Actions capaz de validar, planificar y desplegar infraestructura consumiendo los módulos desarrollados.

El foco no estará únicamente en crear recursos, sino en **construir una forma estandarizada, segura y automatizada de entregar infraestructura**, siguiendo principios de DevOps y Platform Engineering.
