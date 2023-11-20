## Migrating/moving users in terraform state.

There was an array of users (kafka-array-users) defined on variables.tf, so the creation of this users in the terraform state were made using the Terraform count meta argument, so there are some issues regarding the passwords rotation when a user is deleted in an array.

Previously a new kafka-set-user (Set item) was created and populated with the same elements of kafka-array-users array.

The script applied for migrate this to a new Set of users is the following:
```
$ export ENVIRONMENT=sandbox
$ terraform show -json | jq -r '.values.root_module.resources[] | select(.type == "azurerm_key_vault_secret") | select(.name == "kafka-array-users") | "\(.index) \(.values.name) \(.values.id) \(.values.value)" ' | column -t > /tmp/data.txt
$ while IFS= read -r I; do
    words=($(echo $I))
 
    INDEX=${words[0]}
    NAME=${words[1]}
    IDLINK=${words[2]}
    PASS=${words[3]}
 
    echo $INDEX $NAME
 
    # updating new random_password
    RESOURCE="random_password.kafka-set-users[\"${NAME}\"]"
    terraform import -var-file environments/$ENVIRONMENT/variables.tfvars ${RESOURCE} ${PASS}
     
    #updating new kafka-set-user key_vault-secret
    RESOURCE="azurerm_key_vault_secret.kafka-set-users[\"${NAME}\"]"
    terraform import -var-file environments/$ENVIRONMENT/variables.tfvars ${RESOURCE} ${IDLINK}
     
    #delete old random_password
    RESOURCE="random_password.kafka-array-users[${INDEX}]"
    terraform state rm ${RESOURCE}
     
    #delete old kafka-user key_vault_secret
    RESOURCE="azurerm_key_vault_secret.kafka-array-users[${INDEX}]"
    terraform state rm ${RESOURCE}
     
    echo finishing with $INDEX $NAME
    echo ''
done < "/tmp/data.txt"
```