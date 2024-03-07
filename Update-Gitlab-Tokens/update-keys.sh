#!/usr/bin/env bash

CF=/usr/local/etc/keys.conf

DIR=$(yq .config.directory ${CF})
USER=$(yq .config.user ${CF})
# TOKEN > keepassxc-cli show -a Personal.kdbx GITLAB
TOKEN=$(yq .config.token ${CF})
OUTPUT_FILE=$(yq .config.outputFileName ${CF})

createKeyFile () {
  local URL=GITLAB_URL/api/v4/projects/$3/terraform/state/$1
  curl -s https://${USER}:${TOKEN}@${URL} | jq -r .outputs.private_key.value > ${DIR}/${OUTPUT_FILE}_${2}_${1}
  echo ${DIR}/${OUTPUT_FILE}_${2}_${1}
}

chmod 777 -R ${DIR}/${OUTPUT_FILE}*

createKeyFile $(yq .config.aks[0] ${CF}) $(yq .environments[0].name ${CF}) $(yq .environments[0].gitlabId ${CF})
createKeyFile $(yq .config.aks[0] ${CF}) $(yq .environments[1].name ${CF}) $(yq .environments[1].gitlabId ${CF})
createKeyFile $(yq .config.aks[0] ${CF}) $(yq .environments[2].name ${CF}) $(yq .environments[2].gitlabId ${CF})

createKeyFile $(yq .config.aks[1] ${CF}) $(yq .environments[0].name ${CF}) $(yq .environments[0].gitlabId ${CF})
createKeyFile $(yq .config.aks[1] ${CF}) $(yq .environments[1].name ${CF}) $(yq .environments[1].gitlabId ${CF})
createKeyFile $(yq .config.aks[1] ${CF}) $(yq .environments[2].name ${CF}) $(yq .environments[2].gitlabId ${CF})

createKeyFile $(yq .config.aks[2] ${CF}) $(yq .environments[0].name ${CF}) $(yq .environments[0].gitlabId ${CF})
createKeyFile $(yq .config.aks[2] ${CF}) $(yq .environments[1].name ${CF}) $(yq .environments[1].gitlabId ${CF})
createKeyFile $(yq .config.aks[2] ${CF}) $(yq .environments[2].name ${CF}) $(yq .environments[2].gitlabId ${CF})

chmod 400 -R ${DIR}/${OUTPUT_FILE}*

exit 0

