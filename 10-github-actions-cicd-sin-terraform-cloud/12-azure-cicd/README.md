# Ejercicio 12 — Azure CI/CD con GitHub Actions y Terraform CLI

## Objetivo

Desplegar recursos en Azure mediante Terraform CLI y GitHub Actions, guardando el estado de Terraform (**tfstate**) en Azure Blob Storage.

En este ejercicio aprenderás a:

- Crear un backend remoto de Terraform en Azure.
- Crear un Service Principal para la automatización.
- Configurar GitHub Secrets y Variables.
- Corregir la ubicación de un workflow para que GitHub Actions lo detecte.
- Ejecutar validaciones, `plan`, `apply` y `destroy`.

Este laboratorio usa un **client secret** para autenticar el Service Principal. No usa Terraform Cloud ni autenticación federada OIDC.

> **Importante:** el backend de estado debe existir antes de ejecutar `terraform init`. Es independiente de los recursos que Terraform creará en el ejercicio y no debe eliminarse durante `destroy`.

## Arquitectura del ejercicio

1. **Backend preparado manualmente:** Resource Group, Storage Account y container para el tfstate.
2. **GitHub Secrets:** credenciales del Service Principal.
3. **GitHub Variables:** nombres del backend y región de despliegue.
4. **GitHub Actions:** inicializa Terraform, valida, genera el plan y permite aplicar o destruir los recursos.
5. **Estado remoto:** Terraform crea y actualiza el blob de estado en Azure Storage.

---

## 1. Inicia sesión en Azure

Puedes utilizar [Azure Cloud Shell](https://portal.azure.com/) en modo Bash o Azure CLI en tu computadora.

```bash
az login
az account list --output table
```

Selecciona la suscripción que utilizarás para el laboratorio:

```bash
az account set --subscription "<SUBSCRIPTION_ID>"
az account show --query "{subscriptionId:id, tenantId:tenantId, name:name}" --output json
```

Guarda los valores de `subscriptionId` y `tenantId`. Utiliza una suscripción de laboratorio y verifica que tu usuario tenga permisos para crear recursos y asignaciones RBAC.

## 2. Crea el backend remoto del tfstate

El backend se crea **una sola vez** y antes de ejecutar el workflow. Los siguientes comandos crean un Resource Group dedicado, una Storage Account y un container de Blob Storage.

Los nombres de Storage Account deben ser globalmente únicos, tener entre 3 y 24 caracteres y contener únicamente letras minúsculas y números. Cambia el nombre de ejemplo por uno disponible.

```bash
export AZURE_LOCATION="eastus"
export AZURE_STATE_RESOURCE_GROUP="rg-tfstate-lab"
export AZURE_STATE_STORAGE_ACCOUNT="sttfstatealdo12345"
export AZURE_STATE_CONTAINER="tfstate"
export AZURE_STATE_KEY="12-azure-cicd.terraform.tfstate"

# 1. Crear el Resource Group dedicado al estado
az group create \
  --name "$AZURE_STATE_RESOURCE_GROUP" \
  --location "$AZURE_LOCATION"

# 2. Crear la Storage Account del backend
az storage account create \
  --name "$AZURE_STATE_STORAGE_ACCOUNT" \
  --resource-group "$AZURE_STATE_RESOURCE_GROUP" \
  --location "$AZURE_LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --https-only true

# 3. Crear el container que alojará el blob de estado
az storage container create \
  --name "$AZURE_STATE_CONTAINER" \
  --account-name "$AZURE_STATE_STORAGE_ACCOUNT" \
  --auth-mode login
```

El último comando utiliza la identidad con la que iniciaste sesión en Azure CLI. Si recibes un error de autorización, verifica que tu usuario tenga permisos de datos de Blob Storage, por ejemplo, el rol **Storage Blob Data Contributor** sobre la Storage Account. El rol Contributor de administración de Azure no concede automáticamente acceso a los datos del blob.

Estos valores se configurarán después como GitHub Variables:

| Variable | Ejemplo | Uso |
|---|---|---|
| `AZURE_STATE_RESOURCE_GROUP` | `rg-tfstate-lab` | Resource Group que contiene el backend |
| `AZURE_STATE_STORAGE_ACCOUNT` | `sttfstatealdo12345` | Storage Account del backend |
| `AZURE_STATE_CONTAINER` | `tfstate` | Container de Blob Storage |
| `AZURE_STATE_KEY` | `12-azure-cicd.terraform.tfstate` | Nombre del blob de estado |
| `AZURE_LOCATION` | `eastus` | Región donde se crearán los recursos del ejercicio |

Los valores anteriores son ejemplos: registra en GitHub los nombres reales que hayas creado. No almacenes credenciales en Variables.

## 3. Crea el Service Principal para GitHub Actions

El workflow utiliza una identidad de Microsoft Entra ID para desplegar los recursos y acceder al backend remoto.

### 3.1. Crear la identidad

Confirma que seleccionaste la suscripción correcta:

```bash
az account show --query "{subscriptionId:id, tenantId:tenantId}" --output table
```

Crea el Service Principal y asígnale el rol **Contributor** a nivel de la suscripción para este laboratorio:

```bash
az ad sp create-for-rbac \
  --name "sp-gha-terraform-azure-lab" \
  --role "Contributor" \
  --scopes "/subscriptions/$(az account show --query id --output tsv)" \
  --output json
```

La respuesta contiene, entre otros, estos campos:

- `appId`: ID del cliente (Client ID).
- `password`: client secret.
- `tenant`: ID del tenant.

**Guarda el valor de `password` de forma segura en el momento de crearlo.** No lo publiques ni lo guardes en el repositorio. Azure CLI no vuelve a mostrar el secreto en texto plano después de la creación.

> **Alcance de permisos:** Contributor a nivel de suscripción facilita este laboratorio porque Terraform crea un Resource Group nuevo. Es un alcance amplio y debe limitarse a una suscripción de laboratorio. En entornos reales utiliza el mínimo alcance necesario. Crear asignaciones RBAC requiere permisos administrativos adicionales.

### 3.2. Dar acceso al backend remoto

Como el backend usa autenticación Microsoft Entra ID, el Service Principal necesita el rol **Storage Blob Data Contributor** sobre la Storage Account que contiene el tfstate.

Sustituye `<APP_ID>` por el `appId` obtenido en el paso anterior:

```bash
export ARM_CLIENT_ID="<APP_ID>"

export AZURE_STATE_STORAGE_ID="$(az storage account show \
  --name "$AZURE_STATE_STORAGE_ACCOUNT" \
  --resource-group "$AZURE_STATE_RESOURCE_GROUP" \
  --query id --output tsv)"

az role assignment create \
  --assignee "$ARM_CLIENT_ID" \
  --role "Storage Blob Data Contributor" \
  --scope "$AZURE_STATE_STORAGE_ID"
```

La propagación de permisos puede tardar unos minutos. Si la asignación falla, verifica que tu usuario tenga permisos para asignar roles en ese alcance.

## 4. Configura los GitHub Secrets

En el repositorio de GitHub, entra a **Settings → Secrets and variables → Actions → Secrets → New repository secret**.

Configura únicamente estos cuatro Secrets. El workflow los expone como variables de entorno `ARM_*`, que Terraform utiliza para autenticarse con el Service Principal tanto con AzureRM Provider como con el backend `azurerm`. No necesitas `azure/login@v2` ni un Secret JSON adicional.

| Secret | Valor |
|---|---|
| `ARM_CLIENT_ID` | El `appId` del Service Principal |
| `ARM_CLIENT_SECRET` | El `password` del Service Principal |
| `ARM_TENANT_ID` | El ID del tenant, campo `tenant` |
| `ARM_SUBSCRIPTION_ID` | El ID de la suscripción seleccionada |

No publiques el client secret ni lo guardes en el repositorio. Limita el acceso a los Secrets y usa una suscripción de laboratorio.

## 5. Configura las GitHub Variables

Ve a **Settings → Secrets and variables → Actions → Variables → New repository variable** y crea las siguientes cinco Variables:

- `AZURE_STATE_RESOURCE_GROUP`
- `AZURE_STATE_STORAGE_ACCOUNT`
- `AZURE_STATE_CONTAINER`
- `AZURE_STATE_KEY`
- `AZURE_LOCATION`

Utiliza exactamente los mismos valores que configuraste al crear el backend en el paso 2. Las Variables identifican el backend y la región; no deben contener contraseñas ni secretos.

## 6. Mueve el workflow a la ubicación correcta

Este paso es intencional y forma parte del ejercicio.

GitHub Actions detecta automáticamente los workflows del repositorio que se encuentran en la carpeta **`.github/workflows/` de la raíz del repositorio**. En este ejercicio, el archivo está inicialmente dentro de la carpeta del propio ejercicio:

```text
10-github-actions-cicd-sin-terraform-cloud/
└── 12-azure-cicd/
    └── .github/
        └── workflows/
            └── azure-terraform.yml
```

Debes moverlo a la raíz del repositorio y renombrarlo:

```text
.github/
└── workflows/
    └── azure-terraform-cicd.yml
```

Desde la raíz del repositorio, ejecuta:

```bash
mkdir -p .github/workflows

git mv \
  10-github-actions-cicd-sin-terraform-cloud/12-azure-cicd/.github/workflows/azure-terraform.yml \
  .github/workflows/azure-terraform-cicd.yml

git add -A
git commit -m "ci: register Azure Terraform workflow"
git push
```

Después de mover el archivo:

1. **Conserva los filtros `paths`** que apuntan a `10-github-actions-cicd-sin-terraform-cloud/12-azure-cicd/**`. Así, los cambios de este ejercicio activarán el workflow.
2. Conserva el `working-directory` que apunta a la carpeta del ejercicio. Terraform debe ejecutarse desde ese directorio.
3. Revisa que el workflow tenga permisos y Secrets configurados en el repositorio.
4. Entra a la pestaña **Actions** y comprueba que aparezca el workflow **Azure Terraform CLI**.

El workflow anidado no se ejecutará automáticamente desde su ubicación original. Moverlo a la raíz es un requisito de GitHub Actions, no un cambio en el código Terraform.

## 7. ¿Cómo se crea y utiliza el tfstate?

El backend se prepara manualmente; el archivo de estado se crea y actualiza automáticamente cuando Terraform guarda el estado por primera vez.

1. **Preparación inicial:** ya existen el Resource Group, la Storage Account y el container del backend.
2. **`terraform init`:** el workflow inicializa el backend `azurerm` usando los valores de las GitHub Variables y `use_azuread_auth=true`.
3. **Plan y apply:** Terraform lee y actualiza el blob definido por `AZURE_STATE_KEY`. No es necesario crear previamente ese archivo.
4. **Ejecuciones posteriores:** Terraform utiliza el mismo estado remoto para saber qué recursos administra y detectar diferencias.

No intentes crear la Storage Account del backend desde el mismo estado que depende de ella: `terraform init` necesita que el backend exista antes de poder ejecutar Terraform. Si quieres automatizar la creación del backend, hazlo con un estado de bootstrap separado.

## 8. Ejecuta el ejercicio

Una vez configurado el backend, creados los Secrets y Variables, y movido el workflow a la raíz:

1. Crea una rama y modifica un tag en `main.tf`.
2. Abre un Pull Request y revisa las comprobaciones que ejecute el workflow.
3. Integra el cambio en `main`.
4. Entra a **Actions → Azure Terraform CLI → Run workflow**.
5. Selecciona la operación `apply` y ejecuta el workflow manualmente.
6. Verifica en Azure Portal el Resource Group y la Storage Account creados por Terraform.
7. Al terminar el laboratorio, ejecuta nuevamente el workflow y selecciona `destroy`.

El workflow ejecuta `fmt`, `validate` y `plan`; para la ejecución manual, el input permite seleccionar `apply` o `destroy`.

> **Seguridad:** el workflow actual ejecuta un plan autenticado durante eventos de Pull Request y utiliza el ambiente de GitHub llamado `production`. Para un laboratorio, utiliza solo ramas y Pull Requests de confianza y revisa las protecciones del ambiente. En un entorno compartido o productivo, es preferible separar las validaciones sin credenciales de los despliegues autenticados y exigir aprobación antes de aplicar o destruir.

### Qué recursos elimina destroy

`destroy` elimina los recursos que forman parte del estado de este ejercicio, como el Resource Group `rg-gha-tf-azure-lab` y la Storage Account `ghatfazurelab01`, siempre que esos nombres no se hayan modificado.

**No elimines el Resource Group, la Storage Account ni el container del backend remoto durante este paso.** El backend no pertenece al estado de este ejercicio. Revísalo antes de confirmar cualquier operación destructiva.

## Buenas prácticas

- Nunca subas secretos, archivos `.tfstate` ni archivos `.tfstate.backup` a Git.
- Usa una suscripción de laboratorio y una identidad exclusiva para el ejercicio.
- Revisa los planes antes de ejecutar `apply` o `destroy`.
- En entornos productivos, evalúa autenticación federada con GitHub OIDC para evitar client secrets de larga duración.
- Rota o elimina el client secret cuando ya no sea necesario.

## Referencias oficiales

- [Crear un Service Principal con Azure CLI](https://learn.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli)
- [Asignar roles con Azure CLI](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-cli)
- [Crear una Storage Account](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-create)
- [Crear containers de Blob Storage](https://learn.microsoft.com/en-us/azure/storage/blobs/blob-containers-cli)
- [Guardar el estado de Terraform en Azure Storage](https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage)
- [Terraform azurerm backend](https://developer.hashicorp.com/terraform/language/backend/azurerm)
- [GitHub Actions: workflows](https://docs.github.com/en/actions/writing-workflows)
