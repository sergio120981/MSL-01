
## How to update passwords

The following explains how to change the password in the Azure KeyVault, also in the terraform state associated.

These variables can be used to make easier the steps:
```
$ export ENVIRONMENT=sandbox
$ export KEYVAULT=sandbox
$ export PASSWORD=<NEW VALUE>
$ export ITEM=<ITEM NAME>
``` 
### 1. Change password for a secret, create new version of it    
```
$ az keyvault secret set --vault-name $KEYVAULT --name $ITEM --value $PASSWORD
```
From the output take the .id element and save it

### 2. Must search the INDEX of the ITEM into the terraform state 

The same index is for the array element and he random_password object

### 3. Delete the old password in the terraform state by the index
```
$ terraform state rm random_password.ARRAY_ELEMENT[INDEX]
```
### 4. Import the new password into the terraform state 

You can get the password using
```
$ az keyvault secret show --vault-name=$KEYVAULT --name=$ITEM --query "value"
$ terraform import -var-file=environments/$ENVIRONMENT/variables.tfvars random_password.kafka-users[INDEX] $PASSWORD
```
### 5. Delete the resource from the terraform state
```
$ terraform state rm azurerm_key_vault_secret.ARRAY_ELEMENT[INDEX]
```
### 6. Get the new password ID (the same from Step 1)
```
$ ID=$(az keyvault secret show --vault-name=$KEYVAULT --name=$ITEM --query 'id')
```
### 7. Creating in the terraform state the new resource according the new version
```
$ terraform import -var-file=$ENVIRONMENT/variables.tfvars azurerm_key_vault_secret.ARRAY_ELEMENT[INDEX] $ID
```