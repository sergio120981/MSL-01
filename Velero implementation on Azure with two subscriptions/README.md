
This document will describe the installation of Velero and the necessary configuration to save backups from one subscription to another one into Azure, dealing with the security context restrictions.

### 1. Azure configurations needed
Create a new resource group
```
$ az group create -l <LOCATION> -n rg-velero-backup
```
Create a new storage account
```
$ az storage account create \
       --name velerobackupstoracc \
       --resource-group "rg-velero-backup" \
       --sku Standard_GRS \
       --encryption-services blob \
       --https-only true \
       --kind BlobStorage \
       --access-tier Cool
```
Create new container

```
$ az storage container create -n sandbox --public-access off --account-name velerobackupstoracc
```

###2. Download vmware-tanzy/velero repository 
```
$ git clone https://github.com/vmware-tanzu/velero.git
```
Inside the downloaded directory change to use tag v1.12.0
```
$ git checkout tags/v1.12.0
```
### 3. Install CRDs first from the git cloned repository
```
$ kubectl apply -n <NAMESPACE-VELERO-INSTALLATION> -f config/crd/v1/bases/
$ kubectl apply -n <NAMESPACE-VELERO-INSTALLATION> -f config/crd/v2alpha1/bases/
```
### 4. Download and get ready Velero helm repository
```
$ helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
$ mkdir helm-velero && cd helm-velero
$ helm pull vmware-tanzu/velero
$ tar xpf velero-5.0.2.tgz
```
### 5. Prepare values.yaml file

Update the values into the values.yaml file on helm-velero folder structure:
```
image:
  tag: v1.12.0
nameOverride: "velero"
fullnameOverride: "velero"
annotations: 
  meta.helm.sh/release-name: velero
  meta.helm.sh/release-namespace: velero
labels: 
  app.kubernetes.io/managed-by: Helm
initContainers:
  - name: velero-plugin-for-azure
    image: velero/velero-plugin-for-microsoft-azure:v1.8.0
    imagePullPolicy: IfNotPresent
    volumeMounts:
      - mountPath: /target
        name: plugins
configuration:
  backupStorageLocation:
  - name: default
    provider: velero.io/azure
    bucket: sandbox
    credential:
      name: velero-backup-creadentials
      key: velero-backup-creadentials
    config: 
      resourceGroup: rg-velero-testing
      subscriptionId: <BACKUP_SUBSCRIPTION_ID>
      storageAccount: velerobackupstoracc
  volumeSnapshotLocation:
  - name: default
    provider: velero.io/azure
    credential:
      name: velero-backup-credentials
      key: velero-backup-credentials
    config:
      apiTimeout: 15m
      resourceGroup: rg-velero-testing
      subscriptionId: <BACKUP_SUBSCRIPTION_ID>
deployNodeAgent: true
nodeAgent:
  privileged: true
  extraVolumes: 
  - name: tmp
    emptyDir:
      sizeLimit: 1Gi
  extraVolumeMounts: 
  - name: tmp
    mountPath: /tmp
  containerSecurityContext: 
    runAsUser: 0
configMaps: 
  fs-restore-action-config:
    labels:
      velero.io/plugin-config: ""
      velero.io/pod-volume-restore: RestoreItemAction
    data:
      image: velero/velero-restore-helper:v1.12.0 
      cpuRequest: 200m
      memRequest: 128Mi
      cpuLimit: 200m
      memLimit: 128Mi
      secCtx: |
        capabilities:
          drop:
          - ALL
          add: []
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        runAsUser: 1001
        runAsGroup: 999
        seccompProfile: 
          type: RuntimeDefault
```
### 6. Prepare the credentials for the Secrets
In this case we are using one subscription for install velero and other different suscription to store the backups .

Credentials for sandbox (credentials-velero.yaml):
```
AZURE_SUBSCRIPTION_ID="SUBSCRIPTION_ID"
AZURE_TENANT_ID="TENANT"
AZURE_CLIENT_ID="CLIENT_ID"
AZURE_CLIENT_SECRET="CLIENT_SECRET"
AZURE_RESOURCE_GROUP="AKS_RESOURCE_GROUP_TO_BACKUP"
AZURE_CLOUD_NAME=AzurePublicCloud
```
Crendentials for the backup subscription (./velero-backup-credentials)
```
AZURE_SUBSCRIPTION_ID="<BACKUP_SUBSCRIPTION_ID>"
AZURE_TENANT_ID="TENANT"
AZURE_CLIENT_ID="BACKUP_"
AZURE_CLIENT_SECRET="BACKUP_CLIENT_SECRET"
AZURE_RESOURCE_GROUP="rg-velero-testing"
AZURE_CLOUD_NAME=AzurePublicCloud
```
### 7. Create a Secret for the backup subscription
```
$ kubectl create secret generic velero-backup-credentials \
          -n <NAMESPACE-VELERO-INSTALLATION> \
          --from-file=./velero-backup-credentials
```
### 8. Install the Velero helm chart
```
$ helm template --namespace <NAMESPACE-VELERO-INSTALLATION> \
          --set-file credentials.secretContents.cloud=./credentials-velero.yaml . \
          -f values.yaml > full.yaml 
$ kubectl create -f full.yaml
 
# This way, there are also installed servicesaccounts, 
# clusterroles.rbac.authorization.k8s.io,
# clusterrolebindings.rbac.authorization.k8s.io
# and jobs.batch related to the upgrade crds action in Velero
```
Or
```
$ helm upgrade velero --install --namespace <NAMESPACE-VELERO-INSTALLATION> \
          --set-file credentials.secretContents.cloud=./credentials-velero.yaml ./
```
### 9. Velero useful commands
#### 9.1. Take backups
```
$ velero backup create -n <NAMESPACE-VELERO-INSTALLATION> <BACKUP-NAME> \
          --snapshot-volumes --include-namespaces=velero-testing --default-volumes-to-fs-backup
```
#### 9.2. Restore a backup
```
$ velero restore create <RESTORE-NAME> --from-backup=<BACKUP-NAME> \
          -n <NAMESPACE-VELERO-INSTALLATION>
```
#### 9.3. Create a schedule backup in Velero
```
$ velero schedule create -n <NAMESPACE-VELERO-INSTALLATION> <SCHEDULE-NAME> \
          --snapshot-volumes --default-volumes-to-fs-backup \
          --include-namespaces <NAMESPACE-TO-INCLUDE>
          --schedule="0 */6 * * *" --ttl 72h0m0s
```
### 10. Bibliography
https://github.com/vmware-tanzu/helm-charts
https://github.com/vmware-tanzu/velero/tree/v1.12.0