# Sesión 04 — Colaboración con Terraform Cloud

Cinco laboratorios progresivos sobre Terraform Cloud (HCP Terraform). El foco está en workspaces, Remote State, integración VCS, variables sensibles, ejecución remota y automatización de runs.

> **Requisitos:** cuenta en HCP Terraform, GitHub y, para ejercicios con proveedores, una cuenta cloud de laboratorio con permisos mínimos. Revisa límites y funcionalidades de tu plan antes de la clase; algunos nombres de menús pueden cambiar.
>
> **Seguridad:** no subas credenciales al repositorio ni pegues secretos en archivos `.tfvars`, commits, capturas o logs. Usa variables sensibles de workspace o un método de autenticación recomendado para el proveedor. No ejecutes cambios sobre recursos productivos.

## Ruta de aprendizaje

| Ejercicio | Tema | Tiempo sugerido | Resultado |
|---|---|---:|---|
| 1 | Workspace y Remote State | 20 min | Estado almacenado en HCP Terraform |
| 2 | Migración del estado local | 25 min | Migración controlada y verificada |
| 3 | VCS-driven workflow | 30 min | Plan por cambio en GitHub y apply tras aprobación |
| 4 | Variables y datos sensibles | 25 min | Configuración parametrizada sin secretos en Git |
| 5 | Run Triggers y colaboración entre workspaces | 30 min | Flujo de ejecución entre workspaces |

Tiempo total estimado: 2 h 10 min.

---

# Ejercicio 1 — Crear un workspace y usar Remote State

**Nivel:** básico  
**Objetivo:** entender qué representa un workspace de HCP Terraform, cómo se asocia a una configuración y dónde queda el estado remoto.

### Escenario
Un equipo tiene Terraform instalado en las laptops de sus integrantes. Cada persona ejecuta `terraform apply` y termina con un estado distinto o desactualizado. El equipo debe centralizar la gestión del estado.

### Retos
1. Inicia sesión en HCP Terraform y crea una organización o utiliza la organización del laboratorio.
2. Crea un workspace llamado `sesion04-01-remote-state` con flujo **CLI-driven**.
3. En una carpeta local, crea una configuración Terraform mínima que no despliegue recursos cloud. Usa el provider `random` y el recurso `random_pet` para generar un valor de laboratorio.
4. Configura el backend de HCP Terraform con el bloque `cloud` y el nombre de organización/workspace adecuados.
5. Ejecuta `terraform login`, `terraform init`, `terraform plan` y `terraform apply`.
6. Verifica el run y el state desde la UI de HCP Terraform.
7. Cambia un atributo del recurso y observa el nuevo plan.

### Criterios de aceptación
- El workspace aparece en HCP Terraform y está asociado a la configuración CLI.
- El plan y el apply quedan registrados en el historial de runs.
- El alumno explica la diferencia entre el directorio local, el workspace y el state remoto.
- No se requiere crear infraestructura facturable en un proveedor cloud.

### Preguntas de revisión
- ¿Qué información vive en el state?
- ¿Qué riesgo reduce el state remoto?
- ¿El state remoto reemplaza el control de versiones del código?

**Entregable:** captura del workspace y explicación de dónde se consulta el último run y el state.

---

# Ejercicio 2 — Migrar el estado local a HCP Terraform

**Nivel:** intermedio  
**Objetivo:** practicar una migración deliberada del estado local a un workspace remoto, sin perder el seguimiento de los recursos.

### Escenario
Ya existe una configuración Terraform que administra un recurso de laboratorio y el state se guarda localmente. El equipo quiere pasar a HCP Terraform para compartir operaciones y estado.

### Preparación
Usa un directorio independiente del ejercicio 1. Crea un recurso inocuo, como `random_pet`, y ejecuta un apply local para crear el archivo `terraform.tfstate`.

### Retos
1. Registra el estado inicial con `terraform state list` y `terraform state show`.
2. Crea un workspace CLI-driven nuevo: `sesion04-02-migration`.
3. Añade la configuración `cloud` para apuntar al workspace.
4. Lee la salida de `terraform init` y acepta la migración del state cuando Terraform la solicite.
5. Revisa el estado remoto en la UI y compara los recursos gestionados antes y después.
6. Ejecuta `terraform plan` sin cambiar la configuración. El resultado esperado es que no haya cambios.
7. Documenta cómo recuperarías el archivo de state antes de una migración, sin compartirlo ni subirlo al repo.

### Criterios de aceptación
- El state queda asociado al workspace esperado.
- El recurso existente sigue gestionado por Terraform; no se recrea sin motivo.
- Un plan posterior a la migración no muestra cambios inesperados.
- El alumno diferencia **migrar el state** de **importar recursos existentes**.

### Preguntas de revisión
- ¿Por qué conviene hacer una copia de seguridad antes de mover el state?
- ¿Qué revisarías si el plan propone destruir y recrear el recurso?
- ¿Por qué no se debe guardar `terraform.tfstate` en Git?

**Entregable:** salida resumida de `terraform state list` antes/después y explicación del plan de verificación.

---

# Ejercicio 3 — Conectar GitHub y habilitar VCS-driven workflow

**Nivel:** intermedio  
**Objetivo:** automatizar los runs a partir de cambios en el control de versiones y aplicar cambios solamente después de revisar el plan.

### Escenario
El equipo quiere que los cambios enviados a una rama generen un plan verificable, mientras que los cambios aprobados en la rama principal puedan desplegarse con controles.

### Retos
1. Crea una carpeta `08-terraform-cloud/03-vcs-workflow` en tu fork o rama de laboratorio con una configuración Terraform mínima basada en `random_pet`.
2. Crea un workspace llamado `sesion04-03-vcs` con workflow basado en VCS y conéctalo a GitHub mediante la integración disponible en HCP Terraform.
3. Configura el repositorio y el directorio de trabajo correctos.
4. Realiza un commit que cambie el nombre o los atributos del recurso. Verifica que se origine un run.
5. Crea una rama para un segundo cambio y observa el plan que se genera para ese cambio.
6. Revisa el plan antes de confirmar cualquier apply. Configura el workspace para que requiera aprobación manual cuando sea compatible con el flujo elegido.
7. Documenta el recorrido desde el commit hasta el plan, aprobación y resultado.

### Criterios de aceptación
- Un commit en la ruta correcta dispara un run.
- La configuración del workspace apunta al repositorio y directorio esperados.
- Se identifica el commit relacionado con cada run.
- No se aprueba un plan sin revisar las acciones propuestas.

### Preguntas de revisión
- ¿Qué diferencia hay entre CLI-driven y VCS-driven?
- ¿Qué debería suceder cuando falla el plan?
- ¿Por qué una aprobación humana no sustituye la revisión de código?

**Entregable:** URL del workspace y commit que disparó un run, más un diagrama sencillo del flujo.

---

# Ejercicio 4 — Variables, variables sensibles y configuración por entorno

**Nivel:** intermedio  
**Objetivo:** mover la configuración fuera del código y comprender cómo proteger valores sensibles en HCP Terraform.

### Escenario
La misma configuración se utilizará en `dev` y `qa`. Los valores de configuración no deben quedar fijados en el código y las credenciales no pueden almacenarse en Git.

### Retos
1. Usa una configuración Terraform sencilla con variables tipadas:
   - `project_name` (`string`)
   - `environment` (`string`, validación para `dev`, `qa` o `prod`)
   - `resource_count` (`number`, con validación de rango)
   - `tags` (`map(string)`)
2. Expón outputs descriptivos para comprobar los valores introducidos. Evita outputs que revelen secretos.
3. Crea variables de workspace desde la UI: algunas como variables Terraform y otras como variables de entorno.
4. Marca como sensibles los valores de prueba que lo requieran. Si se integra un provider cloud, usa el método de autenticación admitido y recomendado para dicho provider.
5. Ejecuta un plan con `dev` y después con `qa`, usando workspaces separados o una estrategia de entorno claramente documentada.
6. Comprueba cómo aparecen los valores sensibles en la UI y qué se oculta en logs/outputs.
7. Intenta introducir un valor inválido para `environment` y verifica que la validación detenga la ejecución.

### Criterios de aceptación
- Las variables tienen tipos, descripción y validación.
- Separa claramente variables Terraform de variables de entorno.
- Ninguna credencial está en el repositorio ni en archivos versionados.
- Una configuración inválida falla antes de intentar crear recursos.
- Los outputs no filtran valores sensibles.

### Preguntas de revisión
- ¿Qué cambia al marcar una variable como sensible?
- ¿Por qué “sensitive” no es una solución para almacenar secretos en el código?
- ¿Qué diferencias tiene una variable de workspace frente a una variable definida en `.tf`?

**Entregable:** tabla de variables (nombre, tipo, propósito, ubicación y si es sensible) sin incluir los valores secretos.

---

# Ejercicio 5 — Run Triggers y dependencias entre workspaces

**Nivel:** avanzado  
**Objetivo:** coordinar la ejecución de configuraciones separadas, utilizando dependencias explícitas entre workspaces.

### Escenario
Un equipo gestiona una capa de plataforma y otra de aplicación en workspaces distintos. Cuando cambia la plataforma, el workspace dependiente debe poder iniciar una nueva ejecución para validar la configuración consumidora.

### Diseño propuesto
- Workspace A: `sesion04-05-platform`
- Workspace B: `sesion04-05-app`

Para evitar crear infraestructura cloud, ambos pueden usar el provider `random`. Representa un identificador de plataforma con un output y consume dicho output en el workspace B mediante un mecanismo de lectura de outputs remotos disponible para la configuración y los permisos del laboratorio.

### Retos
1. Crea los dos workspaces y sus configuraciones independientes.
2. En A, define un valor de plataforma y publícalo como output no sensible.
3. Configura B para leer el output de A con acceso limitado al workspace productor. No compartas tokens de usuario ni permisos excesivos.
4. Verifica que B pueda leer el output sin copiarlo manualmente.
5. Configura un Run Trigger desde A hacia B en la UI de HCP Terraform, siguiendo las funciones que estén disponibles en tu plan.
6. Ejecuta un cambio en A. Observa el resultado del run y comprueba si el trigger inicia un run en B.
7. Cambia la configuración de B y diferencia qué evento originó cada run.
8. Si el plan o la organización no permite Run Triggers, documenta la limitación y demuestra la dependencia de outputs por separado; no afirmes que existe automatización si no se ejecutó.

### Criterios de aceptación
- Las responsabilidades de los dos workspaces están separadas.
- B consume un output de A mediante permisos explícitos.
- Se identifica el evento que inicia cada run.
- No se exponen outputs sensibles ni se conceden privilegios innecesarios.
- Se documenta el comportamiento observado y cualquier limitación del plan.

### Preguntas de revisión
- ¿Qué ventajas tiene dividir el state por capas?
- ¿Qué acoplamiento introduce depender de outputs remotos?
- ¿Un Run Trigger equivale a un pipeline genérico de CI/CD?

**Entregable:** diagrama de dependencia A → B, evidencias de runs y descripción de permisos.

---

## Checklist común para todos los laboratorios

- [ ] Usé un workspace y nombres exclusivos de laboratorio.
- [ ] Revisé las acciones propuestas en el plan antes de aplicar.
- [ ] No subí credenciales ni state a Git.
- [ ] Documenté los cambios y los resultados de los runs.
- [ ] Destruí los recursos creados, si los hubiera, y confirmé que no quedaron recursos facturables.
- [ ] Dejé los workspaces de práctica identificados para eliminarlos según las políticas del equipo.

## Recursos oficiales

- [HCP Terraform — documentación](https://developer.hashicorp.com/terraform/cloud-docs)
- [Workspaces](https://developer.hashicorp.com/terraform/cloud-docs/workspaces)
- [CLI-driven workflow](https://developer.hashicorp.com/terraform/cloud-docs/run/cli)
- [VCS-driven workflow](https://developer.hashicorp.com/terraform/cloud-docs/run/ui)
- [Variables](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/variables)
- [Remote state](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/state)
- [Run triggers](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/run-triggers)

> Nota docente: HCP Terraform y sus planes pueden cambiar en características, límites y nombres de interfaz. Verifica la disponibilidad de VCS, variables sensibles, outputs remotos y Run Triggers en la organización utilizada para el curso.
