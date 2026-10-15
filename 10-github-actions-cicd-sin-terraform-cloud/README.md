# CI/CD multicloud con GitHub Actions y Terraform CLI (sin Terraform Cloud)

Tres ejercicios separados. Terraform se ejecuta directamente en los runners de GitHub Actions; el state vive en un backend remoto nativo de cada proveedor.

- [12 Azure](./12-azure-cicd): Resource Group + Storage Account; backend Azure Blob.
- [13 AWS](./13-aws-cicd): bucket S3 privado; backend S3.
- [14 GCP](./14-gcp-cicd): bucket Cloud Storage; backend GCS.

En PR/push se ejecutan fmt, init, validate y plan. Apply/destroy son manuales mediante workflow_dispatch. No se usa Terraform Cloud ni OIDC.

Antes de ejecutar, crea manualmente el backend y configura los secrets/variables indicados en cada README. Protege el environment production con required reviewers. No subas credenciales ni state a Git; revisa el plan y destruye los recursos de laboratorio al finalizar.