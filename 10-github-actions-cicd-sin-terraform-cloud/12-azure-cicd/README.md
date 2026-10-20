# Ejercicio 12 — Azure CI/CD con GitHub Actions y Terraform CLI

El objetivo es desplegar recursos en Azure desde GitHub Actions usando Terraform CLI. El estado de Terraform (**tfstate**) se guarda en Azure Blob Storage. Este ejercicio no usa Terraform Cloud ni autenticación federada: utiliza un Service Principal con client secret para el laboratorio.

> **Importante:** crea primero el backend de estado. Terraform necesita poder acceder al backend durante `terraform init`, antes de poder crear los recursos definidos en el ejercicio. El Resource Group, la Storage Account y el container del backend son independientes de los recursos administrados por el Terraform de este ejercicio y no deben borrarse en `destroy`.

## 1. Inicia sesión en Azure

Puedes usar [Azure Cloud Shell](https://portal.azure.com/) (Bash) desde el portal, o Azure CLI en tu computadora.

```bash
az login
az account list --output table
```

Selecciona la suscripción que usarás en el laboratorio:

```bash
az account set --subscription "<SUBSCRIPTION_ID>"
az account show --query "{subscriptionId:id, tenantId:tenantId, name:name}" --output json
```

Guarda el `subscriptionId` y el `tenantId` para la configuración posterior. Usa una suscripción de laboratorio y verifica que tenga permisos para crear recursos y asignaciones RBAC.

## 2. Crea el backend remoto de tfstate

El backend se crea **una sola vez**, antes de ejecutar el workflow. Puedes hacerlo desde Azure Portal o con los siguientes comandos en Bash/Azure Cloud Shell. Los nombres de Storage Account deben ser globalmente únicos, tener entre 3 y 24 caracteres y usar solo letras minúsculas y números. Cambia el sufijo por uno que esté disponible.

```bash
# Ajusta estos valores para tu laboratorio
export AZURE_LOCATION="eastus"
export AZURE_STATE_RESOURCE_GROUP="rg-tfstate-lab"
export AZURE_STATE_STORAGE_ACCOUNT="sttfstatealdo12345"
export AZURE_STATE_CONTAINER="tfstate"
export AZURE_STATE_KEY="12-azure-cicd.terraform.tfstate"

# Crear el Resource Group que alojará exclusivamente el tfstate
az group create \
  --name "$AZURE_STATE_RESOURCE_GROUP" \
  --location "$AZURE_LOCATION"

# Crear la Storage Account para el estado remoto
az storage account create \
  --name "$AZURE_STATE_STORAGE_ACCOUNT" \
  --resource-group "$AZURE_STATE_RESOURCE_GROUP" \
  --location "$AZURE_LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --https-only true

# Crear el container donde Terraform guardará el archivo de estado
az storage container create \
  --name "$AZURE_STATE_CONTAINER" \
  --account-name "$AZURE_STATE_STORAGE_ACCOUNT" \
  --auth-mode login
```

Si el último comando devuelve un error de autorización, verifica que tu usuario tenga los permisos de datos necesarios sobre la Storage Account; el permiso para administrar el recurso de Azure no siempre concede por sí solo acceso a los datos de Blob Storage.

**Valores que debes guardar como GitHub Variables:**

| Variable | Ejemplo | Para qué sirve |
|---|---|---|
| `AZURE_STATE_RESOURCE_GROUP` | `rg-tfstate-lab` | Resource Group del backend |
| `AZURE_STATE_STORAGE_ACCOUNT` | `sttfstatealdo12345` | Storage Account del backend |
| `AZURE_STATE_CONTAINER` | `tfstate` | Container de Blob Storage |
| `AZURE_STATE_KEY` | `12-azure-cicd.terraform.tfstate` | Nombre/ruta del archivo de estado dentro del container |
| `AZURE_LOCATION` | `eastus` | Región para los recursos del ejercicio |

Los ejemplos son ilustrativos: usa tus nombres reales. No pongas contraseñas ni secretos en Variables.

## 3. Crea la identidad de automatización (Service Principal)

El workflow necesita una identidad de Microsoft Entra ID que pueda desplegar los recursos del ejercicio y acceder al backend. Para el laboratorio puedes crear un Service Principal con secreto usando Azure CLI.

### 3.1 Crear el Service Principal

Confirma primero que estás en la suscripción correcta:

```bash
az account show --query "{subscriptionId:id, tenantId:tenantId}" --output table
```

Crea el Service Principal y asígnale el rol **Contributor** a nivel de la suscripción solo para este laboratorio:

```bash
az ad sp create-for-rbac \
  --name "sp-gha-terraform-azure-lab" \
  --role "Contributor" \
  --scopes "/subscriptions/$(az account show --query id --output tsv)" \
  --output json
```

El resultado JSON incluye `appId`, `password` y `tenant`. **Copia el valor de `password` de forma segura en este momento**: no se puede recuperar después como texto plano. No lo publiques ni lo guardes en el repositorio.

> **Permisos:** el alcance de suscripción simplifica un laboratorio que crea un Resource Group nuevo. En entornos reales, prefiere el mínimo alcance posible (por ejemplo, un Resource Group de laboratorio ya existente) y revisa las necesidades de creación y asignación de roles. Asignar roles puede requerir permisos administrativos adicionales.

### 3.2 Dar acceso al backend

El Service Principal también necesita leer y escribir blobs del estado. Obtén su App ID y asigna **Storage Blob Data Contributor** en el alcance de la Storage Account del backend.

```bash
# Sustituye por el appId que devolvió el comando anterior
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

La propagación de permisos puede tardar unos minutos. La asignación de roles podría requerir que quien ejecuta el comando tenga permisos RBAC para crear asignaciones.

## 4. Configura los GitHub Secrets

En GitHub abre el repositorio y entra a **Settings → Secrets and variables → Actions → Secrets → New repository secret**. Crea estos cinco Secrets:

| Secret | Valor |
|---|---|
| `ARM_CLIENT_ID` | El `appId` del Service Principal |
| `ARM_CLIENT_SECRET` | El `password` devuelto al crear el Service Principal |
| `ARM_TENANT_ID` | El `tenantId` de `az account show` o el campo `tenant` del resultado |
| `ARM_SUBSCRIPTION_ID` | El ID de la suscripción elegida |
| `AZURE_CREDENTIALS_JSON` | JSON con los campos `clientId`, `clientSecret`, `subscriptionId` y `tenantId` |

Para `AZURE_CREDENTIALS_JSON`, el contenido debe tener esta forma (reemplaza los valores de ejemplo por los tuyos):

```json
{
  "clientId": "<APP_ID>",
  "clientSecret": "<CLIENT_SECRET>",
  "subscriptionId": "<SUBSCRIPTION_ID>",
  "tenantId": "<TENANT_ID>"
}
```

Pega el JSON como un solo valor de Secret en GitHub; el contenido puede conservar saltos de línea. No pegues las comillas de Markdown ni subas este JSON como archivo al repositorio.

**Nota:** `AZURE_CREDENTIALS_JSON` solo es necesario si el workflow usa una acción como `azure/login` que lo consume. Los Secrets `ARM_*` son los que utiliza Terraform Provider/Backend en la configuración habitual. Si el workflow actual no lee `AZURE_CREDENTIALS_JSON`, el Secret no interviene en la autenticación de ese workflow.

## 5. Configura las GitHub Variables

Ve a **Settings → Secrets and variables → Actions → Variables → New repository variable** y registra las cinco variables del paso 2:

- `AZURE_STATE_RESOURCE_GROUP`
- `AZURE_STATE_STORAGE_ACCOUNT`
- `AZURE_STATE_CONTAINER`
- `AZURE_STATE_KEY`
- `AZURE_LOCATION`

Estas variables identifican el backend y la región. No deben contener credenciales.

## 6. ¿Cómo se crea y utiliza el tfstate?

El flujo es el siguiente:

1. **Preparación inicial (manual):** se crean el Resource Group del backend, la Storage Account y el container.
2. **`terraform init`:** el backend `azurerm` se conecta a esa Storage Account y prepara el estado remoto usando las variables del workflow.
3. **Plan/apply:** Terraform lee y actualiza el blob cuyo nombre se define en `AZURE_STATE_KEY`. El archivo puede no existir antes del primer `apply`; Terraform lo crea al guardar el primer estado.
4. **Ejecuciones siguientes:** el mismo backend y la misma key permiten que los workflows compartan el estado y gestionen el bloqueo cuando corresponda.

No crees la Storage Account del backend desde el mismo estado que depende de ella: sería una dependencia circular, porque `terraform init` necesita que el backend ya exista. Para automatizar también la creación del backend, usa un estado/bootstrap separado y una identidad con permisos adecuados.

## 7. Ejecuta el ejercicio

1. Cambia un tag en una rama y abre un Pull Request.
2. Revisa en **Actions** que pasen `fmt`, `validate` y `plan`.
3. Integra el cambio en `main`.
4. En **Actions → Azure Terraform CLI → Run workflow**, selecciona `apply` si el workflow solicita una operación.
5. Verifica los recursos del ejercicio en Azure Portal.
6. Cuando termines, ejecuta `destroy` desde el workflow para eliminar los recursos administrados por el ejercicio.

**No borres el Resource Group ni la Storage Account del backend durante `destroy`.** Sin el backend, el estado y la coordinación de Terraform podrían perderse. Revisa cuidadosamente el plan antes de confirmar cualquier destrucción.

## Buenas prácticas para el laboratorio

- No guardes secretos, archivos `.tfstate`, ni archivos `.tfstate.backup` en Git.
- No reutilices esta identidad para cargas de trabajo reales.
- En producción, considera GitHub OIDC con autenticación federada en lugar de un client secret de larga duración.
- Protege el ambiente de despliegue con aprobaciones y revisores requeridos.
- Elimina o rota el client secret cuando ya no lo necesites.

## Referencias oficiales

- [Crear un Service Principal con Azure CLI](https://learn.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli)
- [Asignar roles con Azure CLI](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-cli)
- [Crear una Storage Account](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-create)
- [Crear containers de Blob Storage](https://learn.microsoft.com/en-us/azure/storage/blobs/blob-containers-cli)
- [Guardar el estado de Terraform en Azure Storage](https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage)
- [Terraform azurerm backend](https://developer.hashicorp.com/terraform/language/backend/azurerm)
