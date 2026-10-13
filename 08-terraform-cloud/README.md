# Sesión 04 — Colaboración con Terraform Cloud (HCP Terraform)

Esta sesión es **guiada**: sigue los pasos en orden, copia los ejemplos, ejecuta los comandos y comprueba cada resultado antes de avanzar. No necesitas desplegar infraestructura cloud en los ejercicios 1 y 2; se utiliza el provider `random` para practicar con seguridad.

## Requisitos previos

- Git instalado y Terraform CLI instalado (`terraform version`).
- Cuenta en [HCP Terraform](https://app.terraform.io/) y acceso a una organización.
- Cuenta de GitHub y permiso para instalar/conectar la integración VCS en el ejercicio 3.
- Para esta sesión no se necesitan credenciales de AWS/Azure/GCP.
- Crea una carpeta de trabajo fuera de otros proyectos. No subas archivos de state, tokens ni credenciales a Git.

**Duración sugerida:** 2 h 30 min. **Objetivo:** practicar workspaces, state remoto, migración, VCS-driven workflow, variables seguras y Run Triggers.



## Versión de Terraform utilizada

Esta guía está preparada para **Terraform CLI 1.16.5**, la versión estable más reciente verificada para esta actualización. La versión 1.17 aparece como prerelease en el catálogo oficial, así que no se utiliza para el laboratorio. Consulta [HashiCorp Releases](https://releases.hashicorp.com/terraform/) y la [página oficial de instalación](https://developer.hashicorp.com/terraform/install) antes de impartir la sesión por si se publica un parche más reciente.

En todos los bloques HCL, `required_version = "~> 1.16.5"` permite Terraform 1.16.5 y parches compatibles de la rama 1.16, sin saltar automáticamente a una nueva minor.

Comprueba tu versión local:

```bash
terraform version
```

En cada workspace de HCP Terraform, abre **Settings** y revisa la versión de Terraform configurada para las ejecuciones remotas. Selecciona **1.16.5** (o la versión estable parcheada que se acuerde para el curso) para que coincida con la restricción del código. No selecciones una versión beta, alpha o RC para esta práctica.

## Mapa de ejercicios

| # | Ejercicio | Duración |
|---|---|---:|
| 1 | Crear workspace CLI-driven y centralizar el state | 25 min |
| 2 | Migrar state local existente a HCP Terraform | 25 min |
| 3 | Conectar GitHub con VCS-driven workflow | 35 min |
| 4 | Configurar variables y valores sensibles | 25 min |
| 5 | Compartir outputs y configurar Run Triggers | 40 min |

---

# Ejercicio 1 — Crear un workspace y centralizar el state

**Qué aprenderás:** crear un workspace CLI-driven, conectar el CLI con HCP Terraform y revisar los runs y el state desde la web.

## Paso 1. Crear el workspace en HCP Terraform

1. Abre [HCP Terraform](https://app.terraform.io/) e inicia sesión.
2. Entra a tu organización. Si no tienes una, crea una según las opciones disponibles para tu cuenta.
3. Selecciona **Workspaces** y crea un workspace nuevo.
4. Elige el flujo **CLI-driven workflow** (no VCS-driven en este ejercicio).
5. Ponle el nombre `sesion04-01-remote-state` y crea el workspace.
6. Deja abierta la página del workspace. La necesitarás para verificar los resultados.

## Paso 2. Crear una configuración local

En una terminal, ejecuta:

```bash
mkdir -p terraform-cloud-labs/ejercicio-01
cd terraform-cloud-labs/ejercicio-01
```

Crea `main.tf` con este contenido. Reemplaza `MI_ORGANIZACION` por el nombre exacto de tu organización en HCP Terraform.

```hcl
terraform {
  required_version = "~> 1.16.5"

  cloud {
    organization = "MI_ORGANIZACION"

    workspaces {
      name = "sesion04-01-remote-state"
    }
  }

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

resource "random_pet" "demo" {
  length    = 2
  separator = "-"
}

output "nombre_generado" {
  description = "Valor aleatorio generado por Terraform para el laboratorio"
  value       = random_pet.demo.id
}
```

## Paso 3. Autenticar el CLI e inicializar

Ejecuta estos comandos desde `ejercicio-01`:

```bash
terraform login
terraform init
```

- `terraform login` abre el flujo para crear/guardar un token de usuario de Terraform en tu equipo. No compartas el token ni lo guardes en el repositorio.
- `terraform init` descarga el provider `random` y conecta el directorio con el workspace remoto.
- Si aparece un error de organización o workspace, comprueba el nombre exacto en `main.tf` y que tu usuario tenga acceso.

## Paso 4. Ejecutar el primer plan y apply

```bash
terraform fmt
terraform validate
terraform plan
terraform apply
```

Cuando Terraform pregunte si deseas continuar, escribe `yes`. El recurso `random_pet` solo genera un valor en el state; no crea recursos en AWS, Azure ni GCP.

## Paso 5. Comprobar el resultado en la UI

1. Regresa a `sesion04-01-remote-state` en HCP Terraform.
2. Abre **Runs** y verifica que exista un run asociado a tu ejecución.
3. Abre **States** o la sección de state disponible en el workspace y comprueba que se haya guardado una versión.
4. Busca el output `nombre_generado` en el resultado del run.

## Paso 6. Provocar un cambio

En `main.tf`, cambia `length = 2` por `length = 3`. Ejecuta:

```bash
terraform plan
terraform apply
```

Comprueba que se registre otro run y que cambie el valor generado.

### Resultado esperado

- El workspace tiene al menos un run completado.
- El state está guardado remotamente.
- Puedes consultar el output sin depender de que el state esté guardado localmente.

### Preguntas

1. ¿Qué diferencia hay entre el workspace de HCP Terraform y la carpeta local?
2. ¿Qué información registra el state?
3. ¿El state remoto reemplaza a Git? ¿Por qué?

---

# Ejercicio 2 — Migrar un state local a HCP Terraform

**Qué aprenderás:** hacer una migración controlada del state local y comprobar que Terraform continúa gestionando el mismo objeto.

> Haz este ejercicio en otra carpeta y en otro workspace. No reutilices el state del ejercicio 1.

## Paso 1. Crear un workspace remoto vacío

1. En HCP Terraform, crea un workspace CLI-driven llamado `sesion04-02-migration`.
2. No ejecutes ninguna configuración desde la UI; lo conectaremos desde el CLI.

## Paso 2. Crear el state local

Desde una terminal, vuelve al directorio padre y crea una carpeta nueva:

```bash
cd ..
mkdir ejercicio-02
cd ejercicio-02
```

Crea `main.tf` con esta configuración **sin bloque `cloud` ni backend remoto**:

```hcl
terraform {
  required_version = "~> 1.16.5"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

resource "random_pet" "demo" {
  length    = 2
  separator = "-"
}

output "nombre_generado" {
  value = random_pet.demo.id
}
```

Inicializa y aplica localmente:

```bash
terraform init
terraform fmt
terraform validate
terraform apply
```

Escribe `yes` cuando se solicite. Confirma que existen state y recurso:

```bash
terraform state list
terraform state show random_pet.demo
```

Antes de migrar, crea una copia de respaldo **fuera del repositorio**:

```bash
terraform state pull > ../ejercicio-02-state-backup.json
```

Protege ese archivo como dato sensible y no lo compartas. Si tu shell o sistema requiere otra ubicación, guárdalo en una carpeta privada.

## Paso 3. Añadir la configuración de HCP Terraform

Edita el bloque `terraform` de `main.tf` para que quede así, manteniendo el recurso y el output:

```hcl
terraform {
  required_version = "~> 1.16.5"

  cloud {
    organization = "MI_ORGANIZACION"

    workspaces {
      name = "sesion04-02-migration"
    }
  }

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
```

Sustituye `MI_ORGANIZACION` por tu organización.

## Paso 4. Migrar el state

Ejecuta:

```bash
terraform login
terraform init
```

Terraform detectará que el directorio tiene state local y ahora está configurado para utilizar HCP Terraform. Lee el mensaje cuidadosamente y confirma la migración cuando el CLI lo solicite. **No borres manualmente el state local antes de que la migración termine correctamente.**

Si no aparece la pregunta de migración, detente y revisa que estés en `ejercicio-02`, que el state local exista y que el workspace remoto esté vacío y sea el correcto.

## Paso 5. Validar la migración

```bash
terraform state list
terraform plan
```

Abre el workspace `sesion04-02-migration` en HCP Terraform y verifica el state. El plan no debería proponer cambios en el recurso si la configuración y la migración están correctas.

### Resultado esperado

- El recurso `random_pet.demo` sigue presente en el state.
- El state está asociado al workspace remoto.
- Un plan sin cambios de configuración no propone recrear el recurso.

### Preguntas

1. ¿Cuál es la diferencia entre migrar un state e importar un recurso?
2. ¿Por qué hacemos backup antes de migrar?
3. ¿Qué harías si el plan propone destruir y recrear el recurso después de migrar?

---

# Ejercicio 3 — Conectar GitHub con VCS-driven workflow

**Qué aprenderás:** vincular un repositorio, definir el directorio de trabajo y disparar runs al cambiar código.

## Paso 1. Crear una carpeta de laboratorio en tu repo

En tu clon local de `terraform-exercises`, crea una rama para la práctica y el directorio:

```bash
git checkout -b lab/sesion04-terraform-cloud-vcs
mkdir -p 08-terraform-cloud/03-vcs-workflow
```

Dentro de `08-terraform-cloud/03-vcs-workflow`, crea `main.tf`:

```hcl
terraform {
  required_version = "~> 1.16.5"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

resource "random_pet" "demo" {
  length    = 2
  separator = "-"
}

output "nombre_generado" {
  value = random_pet.demo.id
}
```

Crea también `README.md` con el texto `Laboratorio guiado de VCS-driven workflow para HCP Terraform.`

Guarda los archivos y crea un commit:

```bash
git add 08-terraform-cloud/03-vcs-workflow
git commit -m "Add Terraform Cloud VCS lab"
git push -u origin lab/sesion04-terraform-cloud-vcs
```

Si el repositorio es un fork, confirma que `origin` apunta a tu fork y no a un repositorio donde no tengas permiso de escritura.

## Paso 2. Conectar GitHub desde HCP Terraform

1. En HCP Terraform, entra a **Settings** de tu organización y localiza **Providers / Version Control** o la sección equivalente de VCS.
2. Selecciona GitHub y autoriza la aplicación de HCP Terraform siguiendo el flujo de instalación.
3. Concede acceso solamente al repositorio de laboratorio si la pantalla permite elegir repositorios.
4. Vuelve a Workspaces y crea un workspace nuevo.
5. Elige el flujo basado en VCS y selecciona el repositorio `terraform-exercises` (o tu fork).
6. En la configuración del workspace, establece el **Working Directory** como `08-terraform-cloud/03-vcs-workflow`.
7. Selecciona la rama `lab/sesion04-terraform-cloud-vcs` si la UI permite definirla como rama de trabajo. Nombra el workspace `sesion04-03-vcs` y termina la creación.

Los nombres exactos de los menús pueden variar según la versión de la UI y el tipo de organización. Si no puedes instalar la integración, pide al administrador de la organización que la habilite; no sustituyas la conexión por un token pegado en el código.

## Paso 3. Verificar el primer run

1. Abre el workspace `sesion04-03-vcs`.
2. Entra a **Runs** y comprueba si se inició un plan al conectar el repositorio.
3. Abre el run y revisa el commit, la rama y el resultado del plan.
4. Como el recurso es `random_pet`, no hay infraestructura cloud que desplegar.

Si no se inicia automáticamente, revisa el Working Directory, la rama configurada, los permisos de GitHub y que `main.tf` esté en la ruta correcta. Puedes iniciar un run manual desde la UI para comprobar que la configuración se pueda ejecutar, pero registra que fue manual.

## Paso 4. Generar un run con un commit

Edita `main.tf` y cambia `length = 2` por `length = 3`. Luego ejecuta:

```bash
git add 08-terraform-cloud/03-vcs-workflow/main.tf
git commit -m "Change generated pet length"
git push
```

Regresa a **Runs** y localiza el run asociado al nuevo commit. Abre el plan y explica qué va a cambiar.

## Paso 5. Probar una rama o pull request

1. Crea una rama adicional desde tu rama de laboratorio:

```bash
git checkout -b lab/sesion04-vcs-change-2
```

2. Cambia el separador de `random_pet.demo` a `_` o modifica `length`.
3. Haz commit y push de la rama.
4. Abre un pull request hacia tu rama de laboratorio o hacia la rama que configuraste en el workspace.
5. Observa si HCP Terraform genera un **speculative plan** para el pull request. El comportamiento depende de la configuración VCS y de las reglas del workspace.
6. No fusiones el PR hasta haber revisado el diff de Git y el plan de Terraform.

## Paso 6. Revisar el control de apply

En el workspace, revisa la opción de auto-apply. Para esta práctica, mantenla desactivada si está disponible para poder inspeccionar el plan y aprobar el apply manualmente. Si el run de prueba no requiere apply o la configuración de la organización impide esta opción, documenta el comportamiento real observado.

### Resultado esperado

- HCP Terraform está conectado al repositorio.
- El Working Directory apunta al directorio del ejercicio.
- Un commit en la rama configurada genera un run relacionado con ese commit.
- El alumno sabe distinguir un plan normal de un speculative plan.

### Preguntas

1. ¿Qué diferencia hay entre CLI-driven y VCS-driven?
2. ¿Qué información permite relacionar un run con el código fuente?
3. ¿Por qué es importante revisar el plan de Terraform y el diff del PR?

---

# Ejercicio 4 — Variables, validaciones y valores sensibles

**Qué aprenderás:** administrar inputs desde HCP Terraform, validar valores y evitar secretos en el código.

## Paso 1. Crear una configuración con variables

Crea `08-terraform-cloud/04-variables/main.tf` en tu clon del repositorio:

```hcl
terraform {
  required_version = "~> 1.16.5"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

variable "project_name" {
  description = "Nombre corto del proyecto"
  type        = string
  default     = "curso-terraform"
}

variable "environment" {
  description = "Entorno del laboratorio"
  type        = string

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "environment debe ser dev, qa o prod."
  }
}

variable "resource_count" {
  description = "Cantidad de nombres aleatorios que se generarán"
  type        = number
  default     = 1

  validation {
    condition     = var.resource_count >= 1 && var.resource_count <= 3 && floor(var.resource_count) == var.resource_count
    error_message = "resource_count debe ser un entero entre 1 y 3."
  }
}

variable "tags" {
  description = "Etiquetas de referencia del laboratorio"
  type        = map(string)
  default = {
    owner = "alumno"
    lab   = "sesion04"
  }
}

variable "demo_sensitive_value" {
  description = "Valor ficticio para demostrar el tratamiento de variables sensibles; no uses credenciales reales"
  type        = string
  sensitive   = true
}

resource "random_pet" "demo" {
  count     = var.resource_count
  length    = 2
  separator = "-"
}

output "project_environment" {
  description = "Proyecto y entorno seleccionado"
  value       = "${var.project_name}-${var.environment}"
}

output "generated_names" {
  description = "Nombres generados para el laboratorio"
  value       = random_pet.demo[*].id
}

output "tags_configured" {
  description = "Etiquetas configuradas"
  value       = var.tags
}
```

## Paso 2. Crear un workspace

1. En HCP Terraform, crea un workspace CLI-driven llamado `sesion04-04-dev`.
2. Configura el bloque `cloud` en `main.tf` para que apunte a tu organización y a ese workspace. Como este laboratorio utiliza variables de workspace, puedes mantener el bloque `cloud` en la misma configuración.
3. Ejecuta `terraform login` si todavía no has autenticado el CLI y luego `terraform init`.
4. Si el workspace está conectado por CLI, desde el directorio `08-terraform-cloud/04-variables` ejecuta los siguientes comandos de formato y validación:

```bash
terraform fmt
terraform validate
```

## Paso 3. Configurar variables en la UI

1. Abre el workspace `sesion04-04-dev` y entra en **Variables**.
2. Crea una variable de tipo **Terraform** llamada `environment`, con valor `dev`.
3. Crea una variable Terraform `resource_count` con valor `2`.
4. Crea una variable Terraform `tags` con valor JSON, por ejemplo:

```json
{"owner":"alumno","lab":"sesion04","cost-center":"training"}
```

5. Crea `demo_sensitive_value` como variable Terraform, introduce un valor ficticio que no sea una contraseña real y marca la opción **Sensitive**.
6. Guarda las variables. No captures ni copies el valor sensible en el entregable.
7. Ejecuta `terraform plan` y revisa que el run utilice `dev`, cree dos instancias de `random_pet.demo` y no muestre el valor sensible.

**Importante:** si trabajas con un workspace VCS-driven, el plan se dispara desde commits/UI y las variables se administran igualmente desde la sección Variables. No intentes ejecutar `terraform apply` local contra un workspace configurado para un flujo distinto sin entender primero el modo de ejecución.

## Paso 4. Probar la validación

1. Cambia temporalmente la variable `environment` en la UI a `testing`.
2. Ejecuta un nuevo plan.
3. Lee el error de validación: debe indicar que solo se aceptan `dev`, `qa` o `prod`.
4. Devuelve el valor a `dev` para dejar el workspace en estado correcto.

## Paso 5. Comparar entornos

1. Crea otro workspace CLI-driven llamado `sesion04-04-qa`.
2. Configura la misma organización y el workspace `sesion04-04-qa` en el bloque `cloud` para la copia de configuración que utilizarás con QA.
3. Define las mismas variables, pero establece `environment = qa` y `resource_count = 1`.
4. Ejecuta un plan y compara los outputs de ambos workspaces.

### Resultado esperado

- Los inputs se administran desde HCP Terraform y no están fijados todos en el código.
- El valor inválido es rechazado por la validación.
- La variable sensible está marcada como tal y no se imprime como output.
- `dev` y `qa` tienen configuraciones de variables separadas.

### Preguntas

1. ¿Cuál es la diferencia entre una variable Terraform y una variable de entorno?
2. ¿Qué oculta la marca `sensitive` y qué no soluciona?
3. ¿Por qué no debemos guardar secretos en `.tfvars` versionados?

---

# Ejercicio 5 — Outputs remotos y Run Triggers entre workspaces

**Qué aprenderás:** separar componentes en workspaces distintos, compartir outputs con permisos y observar una dependencia de ejecución.

> Este ejercicio requiere que la organización y el plan permitan la función de Run Triggers y la lectura de outputs remotos. Si una función no está disponible, completa primero la parte de outputs y registra la limitación sin simular que el trigger funcionó.

## Paso 1. Crear los dos workspaces

En HCP Terraform crea dos workspaces CLI-driven:

- `sesion04-05-platform`
- `sesion04-05-app`

La idea es que **platform** publique un identificador y **app** lo consuma. No desplegaremos recursos cloud.

## Paso 2. Configurar el workspace platform

Crea `08-terraform-cloud/05-workspaces/platform/main.tf` con este contenido. Reemplaza `MI_ORGANIZACION`:

```hcl
terraform {
  required_version = "~> 1.16.5"

  cloud {
    organization = "MI_ORGANIZACION"
    workspaces {
      name = "sesion04-05-platform"
    }
  }

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

variable "platform_revision" {
  description = "Revisión lógica de la plataforma para demostrar cambios"
  type        = string
  default     = "v1"
}

resource "random_pet" "platform" {
  length    = 2
  separator = "-"
  keepers = {
    revision = var.platform_revision
  }
}

output "platform_id" {
  description = "Identificador no sensible publicado por platform"
  value       = random_pet.platform.id
}

output "platform_revision" {
  value = var.platform_revision
}
```

Desde esa carpeta, ejecuta `terraform login` si hace falta y luego:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Escribe `yes` para aplicar. Comprueba que `platform_id` aparece como output del workspace.

## Paso 3. Permitir lectura de outputs

1. En HCP Terraform, abre `sesion04-05-platform` y localiza la sección de acceso a outputs/state compartido o **Remote state sharing**.
2. Configura el acceso para que `sesion04-05-app` pueda leer los outputs de `platform`, si la política y el plan lo permiten.
3. Concede el mínimo acceso necesario. No compartas tokens personales en el repositorio ni concedas acceso a toda la organización si no hace falta.
4. Si la UI muestra opciones distintas, consulta la documentación oficial de Remote State y sigue el mecanismo admitido por la organización.

## Paso 4. Configurar el workspace app

Crea `08-terraform-cloud/05-workspaces/app/main.tf`:

```hcl
terraform {
  required_version = "~> 1.16.5"

  cloud {
    organization = "MI_ORGANIZACION"
    workspaces {
      name = "sesion04-05-app"
    }
  }

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

data "terraform_remote_state" "platform" {
  backend = "remote"

  config = {
    organization = "MI_ORGANIZACION"
    workspaces = {
      name = "sesion04-05-platform"
    }
  }
}

resource "random_pet" "app" {
  length    = 2
  separator = "-"
  keepers = {
    platform_id = data.terraform_remote_state.platform.outputs.platform_id
  }
}

output "platform_id_consumed" {
  description = "Output que app consume desde platform"
  value       = data.terraform_remote_state.platform.outputs.platform_id
}

output "app_id" {
  value = random_pet.app.id
}
```

Reemplaza `MI_ORGANIZACION` en los dos lugares donde aparece. Desde la carpeta `app`, ejecuta:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Si falla la lectura del output, comprueba primero que `platform` tenga un apply completado y que el acceso de outputs remotos esté habilitado para el workspace consumidor. No soluciones el error copiando un token secreto al código.

## Paso 5. Configurar un Run Trigger

1. En HCP Terraform, abre el workspace `sesion04-05-app`.
2. Localiza **Settings** y la sección **Run Triggers** (el menú puede variar).
3. Añade `sesion04-05-platform` como workspace que puede disparar ejecuciones de `app`, si esta opción está disponible.
4. Guarda la configuración y vuelve a `platform`.
5. Cambia `platform_revision` de `v1` a `v2`. Puedes hacerlo mediante una variable de workspace si decides definirla allí; si no, cambia el `default` en el código.
6. Ejecuta un nuevo plan y apply de `platform`.
7. Abre Runs en `app` y comprueba si el cambio de `platform` inició un run en el workspace dependiente. Anota el origen y el resultado.

Un Run Trigger inicia una ejecución en el workspace dependiente; no equivale a una garantía de que todos los cambios se apliquen automáticamente. Revisa siempre el plan y el control de aprobación configurado.

## Paso 6. Dibujar el flujo y validar

Documenta el flujo:

```text
Cambio de configuración en platform
              |
              v
     Run en platform
              |
              v
     Run Trigger (si está habilitado)
              |
              v
         Run en app
              |
              v
  app lee output de platform
```

### Resultado esperado

- `platform` publica un output no sensible.
- `app` consume ese output sin copiar manualmente el valor.
- El acceso está limitado al workspace necesario.
- El alumno puede mostrar si el Run Trigger se ejecutó realmente o explicar qué limitación lo impidió.

### Preguntas

1. ¿Qué ventajas tiene dividir una plataforma en varios workspaces?
2. ¿Qué dependencia y acoplamiento genera `terraform_remote_state`?
3. ¿Qué diferencia hay entre compartir outputs y disparar un run?

---

## Checklist final del alumno

- [ ] Puedo explicar qué es un workspace y dónde se almacena el state remoto.
- [ ] Migré state local y comprobé que el plan no tuviera cambios inesperados.
- [ ] Conecté GitHub y relacioné un run con un commit.
- [ ] Configuré variables tipadas y una variable sensible sin revelar su valor.
- [ ] Probé el consumo de outputs entre workspaces y registré el resultado del Run Trigger.
- [ ] No subí tokens, credenciales ni archivos de state al repositorio.
- [ ] Eliminé los workspaces temporales según las indicaciones del instructor cuando ya no sean necesarios.

## Limpieza de los laboratorios

Los ejercicios 1, 2 y 4 usan recursos del provider `random`, no recursos de infraestructura cloud. Para quitar los recursos gestionados, entra al directorio de cada workspace CLI-driven y ejecuta `terraform destroy` si el flujo y la configuración siguen disponibles. Confirma el plan antes de escribir `yes`.

Para los workspaces VCS-driven, revisa primero las opciones de destrucción disponibles en la UI. No elimines el workspace hasta confirmar que ya no lo necesitas y que el state se ha tratado según las políticas de tu equipo. Elimina ramas de prueba y carpetas locales cuando hayas entregado las evidencias. Nunca borres un state a mano como sustituto de `destroy`.



---

# Ejercicio 6 — Desplegar un bucket S3 en AWS desde HCP Terraform

**Nivel:** avanzado  
**Duración sugerida:** 40–50 minutos  
**Objetivo:** desplegar un recurso real de AWS con ejecución remota, state administrado por HCP Terraform y autenticación temporal OIDC, sin guardar access keys en el workspace.

**Arquitectura del laboratorio:** GitHub/CLI → HCP Terraform (plan y apply remoto) → OIDC → rol IAM limitado → bucket S3 privado.

> **Costos y permisos:** necesitas una cuenta AWS de laboratorio y permisos para configurar IAM OIDC, roles y políticas. Aunque un bucket vacío suele tener un costo directo mínimo o nulo, AWS puede cobrar por almacenamiento, solicitudes y otros servicios. No uses una cuenta productiva. Si no tienes permisos IAM, solicita al administrador que prepare el proveedor OIDC, el rol y la política. No crees access keys de larga duración para resolver problemas de permisos.

## Paso 1. Crear un workspace de HCP Terraform

1. En HCP Terraform, crea un workspace CLI-driven llamado `sesion04-06-aws-s3`.
2. Anota el nombre de tu organización y, si corresponde, el proyecto de HCP Terraform al que pertenece.
3. En **Settings**, localiza la configuración de ejecución y selecciona Terraform **1.16.5**, siempre que siga siendo la versión estable aprobada para el curso. La restricción del código debe ser compatible con esa versión.
4. No ejecutes aún ningún apply: primero configuraremos el acceso a AWS.

## Paso 2. Crear la relación de confianza OIDC en AWS

La forma más sencilla para el laboratorio es usar la opción oficial **AWS Quick Setup** desde la página Variables del workspace, si está disponible y tienes permisos de administrador de IAM. Esta opción guía la configuración de confianza y credenciales dinámicas. Consulta [AWS quick setup de HCP Terraform](https://developer.hashicorp.com/terraform/cloud-docs/dynamic-provider-credentials/aws-configuration/quick-setup).

Si debes configurarlo manualmente, sigue la guía oficial de [credenciales dinámicas AWS](https://developer.hashicorp.com/terraform/cloud-docs/dynamic-provider-credentials/aws-configuration):

1. En la consola AWS, abre **IAM → Identity providers** y verifica si ya existe el proveedor OIDC `https://app.terraform.io`. No intentes crear un duplicado.
2. Si no existe, crea un proveedor OpenID Connect con URL `https://app.terraform.io` y audience `aws.workload.identity`.
3. Crea un rol IAM para HCP Terraform. En la relación de confianza, permite asumir el rol mediante `sts:AssumeRoleWithWebIdentity` solo al proveedor OIDC de HCP Terraform.
4. Limita la condición de audiencia a `aws.workload.identity`.
5. Restringe la condición `sub` al workspace de este laboratorio, usando el formato documentado por HashiCorp para tu organización/proyecto/workspace. No uses una condición comodín que permita a cualquier workspace de cualquier organización asumir el rol.
6. Adjunta al rol una política de permisos para el bucket del ejercicio. Para enseñar mínimo privilegio, limita las operaciones de lectura/actualización/borrado al ARN del bucket de laboratorio y sus objetos. La creación inicial del bucket puede requerir `s3:CreateBucket` sobre `*`; si se concede, limita esa excepción al rol exclusivo del laboratorio y retírala cuando ya no se necesite. No concedas `AdministratorAccess`.

**Importante:** los nombres exactos de los campos de trust policy dependen del método de configuración. Usa el ejemplo de política de confianza de la documentación oficial y sustituye los valores por los de tu organización y workspace; no copies una política genérica sin restringirla.

## Paso 3. Configurar credenciales dinámicas en el workspace

1. Regresa a HCP Terraform y abre el workspace `sesion04-06-aws-s3`.
2. En **Variables**, agrega las siguientes variables de entorno:

| Nombre | Valor |
|---|---|
| `TFC_AWS_PROVIDER_AUTH` | `true` |
| `TFC_AWS_RUN_ROLE_ARN` | ARN del rol IAM creado para el laboratorio |
| `AWS_REGION` | Región aprobada por el instructor, por ejemplo `us-east-1` |

3. Guarda las variables. No agregues `AWS_ACCESS_KEY_ID` ni `AWS_SECRET_ACCESS_KEY`: el objetivo es que HCP Terraform obtenga credenciales temporales mediante OIDC.
4. Confirma que la trust policy del rol permite a este workspace y que el rol tiene los permisos S3 necesarios.

## Paso 4. Crear la configuración Terraform

En tu repositorio `terraform-exercises`, crea el directorio `08-terraform-cloud/06-aws-s3`. Crea un archivo `main.tf` con el siguiente contenido y sustituye `MI_ORGANIZACION` por el nombre exacto de tu organización:

```hcl
terraform {
  required_version = "~> 1.16.5"

  cloud {
    organization = "MI_ORGANIZACION"

    workspaces {
      name = "sesion04-06-aws-s3"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "Región AWS configurada en el workspace"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name_prefix" {
  description = "Prefijo único para el bucket del laboratorio"
  type        = string
  default     = "tfcloud-sesion06-lab"
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "lab" {
  bucket = "${var.bucket_name_prefix}-${random_id.suffix.hex}"

  tags = {
    Name        = "tfcloud-sesion06"
    Environment = "training"
    ManagedBy   = "HCP-Terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "lab" {
  bucket = aws_s3_bucket.lab.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lab" {
  bucket = aws_s3_bucket.lab.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

output "bucket_name" {
  description = "Nombre del bucket privado creado en el laboratorio"
  value       = aws_s3_bucket.lab.bucket
}

output "bucket_arn" {
  description = "ARN del bucket creado"
  value       = aws_s3_bucket.lab.arn
}
```

Crea además un archivo `.gitignore` para evitar añadir artefactos locales o credenciales:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
crash.log
crash.*.log
```

No añadas archivos que contengan tokens, credenciales ni state. La configuración no necesita un archivo de credenciales AWS.

## Paso 5. Inicializar y conectar el directorio al workspace

Desde la raíz de tu clon local, ejecuta:

```bash
cd 08-terraform-cloud/06-aws-s3
terraform version
terraform login
terraform init
terraform fmt
terraform validate
```

1. Verifica que `terraform version` muestre una versión compatible con `required_version`.
2. `terraform init` descargará los providers y conectará el directorio con el workspace remoto.
3. Si aparece un error de versión, proveedor o workspace, corrige el problema antes de continuar.

## Paso 6. Revisar el plan remoto

Ejecuta:

```bash
terraform plan
```

1. Abre el workspace en HCP Terraform y entra a **Runs**.
2. Abre el run y revisa las acciones propuestas.
3. Comprueba que se crearán el bucket, el bloqueo de acceso público y la configuración de cifrado.
4. Si aparece `AccessDenied`, no amplíes permisos a administrador por ensayo y error. Revisa el ARN del rol, la condición OIDC, la región y la política IAM.
5. Si el plan es correcto, continúa con el apply.

## Paso 7. Aplicar y verificar en AWS

Ejecuta:

```bash
terraform apply
```

Revisa el plan que presenta Terraform y escribe `yes` solo si las acciones son las esperadas. La operación se ejecutará remotamente en HCP Terraform.

Después:

1. En HCP Terraform, comprueba que el run finalizó correctamente.
2. Copia el valor de salida `bucket_name` (no contiene secretos).
3. En la consola AWS, abre **S3** y verifica que el bucket exista.
4. En la pestaña de permisos, confirma que el bloqueo de acceso público esté habilitado.
5. En las propiedades del bucket, verifica que el cifrado predeterminado esté habilitado.
6. Comprueba en HCP Terraform que el state remoto registra los recursos creados.

No configures el bucket como público ni subas datos reales.

## Paso 8. Hacer un cambio controlado

Añade una etiqueta adicional al bloque `tags` del bucket:

```hcl
CostCenter = "training"
```

Guarda el archivo y ejecuta:

```bash
terraform fmt
terraform plan
terraform apply
```

Comprueba que el plan propone actualizar etiquetas sin reemplazar el bucket. Revisa el resultado del run en HCP Terraform.

## Paso 9. Destruir los recursos del laboratorio

Al terminar, ejecuta:

```bash
terraform destroy
```

Revisa el plan de destrucción y escribe `yes` solo si corresponde a los recursos de este laboratorio. Luego verifica en la consola S3 que el bucket ya no exista. Si AWS indica que el bucket no está vacío, revisa su contenido y elimina únicamente los objetos de prueba del laboratorio según las indicaciones del instructor; no borres datos ajenos.

Después de confirmar que ya no necesitas el laboratorio, el administrador puede retirar los permisos de creación que concedió al rol y eliminar el rol/proveedor OIDC solo si no lo utiliza ningún otro workspace.

## Criterios de aceptación

- [ ] HCP Terraform ejecutó el plan y el apply de forma remota.
- [ ] La autenticación a AWS se realizó mediante OIDC y credenciales temporales.
- [ ] No se almacenaron access keys permanentes en el workspace ni en Git.
- [ ] El bucket tiene bloqueo de acceso público y cifrado predeterminado.
- [ ] El state está en HCP Terraform.
- [ ] Se aplicó una actualización de etiquetas sin reemplazar el bucket.
- [ ] Se destruyeron los recursos al finalizar.

## Preguntas de revisión

1. ¿Qué diferencia hay entre las credenciales temporales OIDC y las access keys estáticas?
2. ¿Por qué la trust policy debe restringir el workspace que puede asumir el rol?
3. ¿Qué ventajas aporta el state remoto al trabajo en equipo?
4. ¿Por qué revisamos el plan antes de aprobar el apply?
5. ¿Qué permisos mínimos necesitó el rol y cuáles retirarías al finalizar?

## Referencias oficiales

- [HCP Terraform — AWS dynamic credentials](https://developer.hashicorp.com/terraform/cloud-docs/dynamic-provider-credentials/aws-configuration)
- [HCP Terraform — AWS Quick Setup](https://developer.hashicorp.com/terraform/cloud-docs/dynamic-provider-credentials/aws-configuration/quick-setup)
- [HCP Terraform — Dynamic provider credentials](https://developer.hashicorp.com/terraform/cloud-docs/dynamic-provider-credentials)
- [AWS — Crear un proveedor OIDC en IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [AWS Provider — documentación](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)


## Documentación oficial

- [HCP Terraform](https://developer.hashicorp.com/terraform/cloud-docs)
- [CLI-driven workflow](https://developer.hashicorp.com/terraform/cloud-docs/run/cli)
- [VCS-driven workflow](https://developer.hashicorp.com/terraform/cloud-docs/run/ui)
- [Variables de workspace](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/variables)
- [State y workspaces](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/state)
- [Run Triggers](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/run-triggers)

> **Nota del instructor:** los nombres de opciones y las capacidades disponibles dependen de la versión de HCP Terraform, permisos y plan de la organización. Verifica las pantallas antes de dictar la sesión. No uses credenciales productivas en estos laboratorios.
