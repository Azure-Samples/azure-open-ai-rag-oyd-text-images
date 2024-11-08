#! /bin/bash

region="eastus"
template_file="main.bicep"
bicep_deployment_name="main"
resource_group_name="aoai-rag-oyd"

index_name="search-aoai-emb"
api_version="2024-09-01-preview"
search_semanic_config=search-aoai-emb-semantic-configuration
search_query_type=vector_semantic_hybrid

container_name="data"
file_name="${file_name:-"Azure-Kubernetes-Service.pdf"}"
dest_file_path="raw_data/${file_name}"
source_file_path="./sample-documents/${file_name}"

model_deployment_name_embedding="${resource_group_name}-embedding"
model_name_embedding="text-embedding-ada-002"
model_version_embedding="1"
model_deployment_name_chat="${resource_group_name}-chat"
model_name_chat="gpt-4o"
model_version_chat="2024-08-06"

create_ai_search_data_source() {
    echo ">>> Creating AI Search data source"
    echo '{"msg": ">>> creating datasource"}' >> ai_search_logs.jsonl
    datasource=`cat datasource.json`

    datasource=`echo $datasource | sed -e "s/INDEX_NAME_HERE/${index_name}/g"`
    datasource=`echo $datasource | sed -e "s/SUBSCRIPTION_ID_HERE/${subscription_id}/g"`
    datasource=`echo $datasource | sed -e "s/RESOURCE_GROUP_NAME_HERE/${resource_group_name}/g"`
    datasource=`echo $datasource | sed -e "s/STORAGE_ACCOUNT_NAME_HERE/${storage_account_name}/g"`

    curl "${base_url}/datasources?api-version=${api_version}" \
        -H "Content-Type: application/json" \
        -H "api-key: ${search_service_key}" \
        --data-binary "${datasource}" >> ai_search_logs.jsonl

    echo "" >> ai_search_logs.jsonl && echo '{"msg": "<<< creating datasource completed"}' >> ai_search_logs.jsonl
    echo "<<< Creating AI Search data source completed"
}

create_ai_search_index() {
    echo '{"msg": ">>> creating index"}' >> ai_search_logs.jsonl
    index=`cat index.json`

    index=`echo $index | sed -e "s/AOAI_API_KEY_HERE/${AZURE_OPENAI_KEY}/g"`
    index=`echo $index | sed -e "s/INDEX_NAME_HERE/${index_name}/g"`
    index=`echo $index | sed -e "s|AOAI_URI_HERE|${AZURE_OPENAI_ENDPOINT}|g"`
    index=`echo $index | sed -e "s/AOAI_DEPLOYMENT_ID_HERE/${AZURE_OPENAI_CHATGPT_EMBEDDING_DEPLOYMENT}/g"`
    index=`echo $index | sed -e "s/AOAI_MODEL_NAME_HERE/${AZURE_OPENAI_CHATGPT_EMBEDDING_MODEL_NAME}/g"`

    curl "${base_url}/indexes?api-version=${api_version}" \
        -H "Content-Type: application/json" \
        -H "api-key: ${search_service_key}" \
        --data-binary "${index}" >> ai_search_logs.jsonl
    
    echo "" >> ai_search_logs.jsonl && echo '{"msg": "<<< creating index completed"}' >> ai_search_logs.jsonl
}

create_ai_search_skillset() {
    echo '{"msg": ">>> creating skillest"}' >> ai_search_logs.jsonl
    skillset=`cat skillset.json`

    skillset=`echo $skillset | sed -e "s/AOAI_API_KEY_HERE/${AZURE_OPENAI_KEY}/g"`
    skillset=`echo $skillset | sed -e "s/INDEX_NAME_HERE/${index_name}/g"`
    skillset=`echo $skillset | sed -e "s|AOAI_URI_HERE|${AZURE_OPENAI_ENDPOINT}|g"`
    skillset=`echo $skillset | sed -e "s/AOAI_DEPLOYMENT_ID_HERE/${AZURE_OPENAI_CHATGPT_EMBEDDING_DEPLOYMENT}/g"`
    skillset=`echo $skillset | sed -e "s/AOAI_MODEL_NAME_HERE/${AZURE_OPENAI_CHATGPT_EMBEDDING_MODEL_NAME}/g"`

    curl "${base_url}/skillsets?api-version=${api_version}" \
        -H "Content-Type: application/json" \
        -H "api-key: ${search_service_key}" \
        --data-binary "${skillset}" >> ai_search_logs.jsonl

    echo "" >> ai_search_logs.jsonl && echo '{"msg": "<<< creating skillset completed"}' >> ai_search_logs.jsonl
}

create_ai_search_indexer() {
    echo '{"msg": ">>> creating indexer"}' >> ai_search_logs.jsonl
    indexer=`cat indexer.json`

    indexer=`echo $indexer | sed -e "s/INDEX_NAME_HERE/${index_name}/g"`

    curl "${base_url}/indexers?api-version=${api_version}" \
        -H "Content-Type: application/json" \
        -H "api-key: ${search_service_key}" \
        --data-binary "${indexer}" >> ai_search_logs.jsonl
    
    echo "" >> ai_search_logs.jsonl && echo '{"msg": "<<< creating indexer completed"}' >> ai_search_logs.jsonl
}

get_bicep_output_value() {
  az deployment group show \
      -g "${resource_group_name}" \
      -n "${bicep_deployment_name}" \
      --query properties.outputs.${1}.value \
      -o tsv
}

get_blob_sas_token() {
  expiry_30_days=$(date --date="30 days" +"%Y-%m-%d")
  storage_account_name=$(get_bicep_output_value storage_account_name)

  connection_string=$(az storage account show-connection-string \
    --name "${storage_account_name}" \
    --resource-group ${resource_group_name} \
    --output tsv)

  sas_token_value=$(az storage container generate-sas \
    --connection-string "${connection_string}" \
    -n "${container_name}" \
    --permissions r \
    --expiry "${expiry_30_days}" \
    --output tsv)

  echo "sas_token=\"${sas_token_value}\"" >> ./.env
}

load_dot_env() {
  source .env
}

load_dot_env_aoai() {
  source .env_aoai
}

configure_demo_app_env_file() {
  load_dot_env
  load_dot_env_aoai
  
  echo "" > ./demo-app/.env
  echo "AZURE_OPENAI_ENDPOINT=${AZURE_OPENAI_ENDPOINT}" >> ./demo-app/.env
  echo "AZURE_OPENAI_KEY=${AZURE_OPENAI_KEY}" >> ./demo-app/.env
  echo "AZURE_OPENAI_CHATGPT_DEPLOYMENT=${AZURE_OPENAI_CHATGPT_DEPLOYMENT}" >> ./demo-app/.env
  echo "AZURE_OPENAI_API_VERSION=${AZURE_OPENAI_API_VERSION}" >> ./demo-app/.env
  echo "AZURE_OPENAI_CHATGPT_EMBEDDING_DEPLOYMENT=${AZURE_OPENAI_CHATGPT_EMBEDDING_DEPLOYMENT}" >> ./demo-app/.env

  echo "SEARCH_ENDPOINT=${base_url}" >> ./demo-app/.env
  echo "SEARCH_INDEX=${index_name}" >> ./demo-app/.env
  echo "SEARCH_API_KEY=${search_service_key}" >> ./demo-app/.env
  echo "SEARCH_SEMANTIC_CONFIGURATION=${search_semanic_config}" >> ./demo-app/.env
  echo "SEARCH_QUERY_TYPE=${search_query_type}" >> ./demo-app/.env
  echo "BLOB_SAS_TOKEN=\"${sas_token}\"" >> ./demo-app/.env
}

case $@ in
  load_dot_env|lde|load)
    load_dot_env
    echo "${sas_token}"
    ;;
  create-resource-group|crg)
    echo ">>> Creating resource group"
    az group create --name "${resource_group_name}" --location "${region}"
    echo "<<< Creating resource group completed"
    ;;
  deploy-bicep)
    echo ">>> Deploying bicep template"
    cd bicep

    az deployment group create --resource-group "${resource_group_name}" --template-file "${template_file}"
    echo "<<< Deploying bicep template completed"
    ;;
  delete-resource-group|drg|cleanup|down)
    echo ">>> Deleting resource group"
    az group delete --resource-group "${resource_group_name}" -y
    echo "<<< Deleting resource group completed"
    ;;
  create-ai-search-data-source)
    load_dot_env
    load_dot_env_aoai
    cd ./bicep/helpers

    create_ai_search_data_source
    ;;
  create-ai-search-index)
    load_dot_env
    load_dot_env_aoai
    cd ./bicep/helpers

    create_ai_search_index
    ;;
  create-ai-search-skillset)
    load_dot_env
    load_dot_env_aoai
    cd ./bicep/helpers

    create_ai_search_skillset
    ;;
  create-ai-search-indexer)
    load_dot_env
    load_dot_env_aoai
    cd ./bicep/helpers

    create_ai_search_indexer
    ;;
  setup-ai-search)
    echo ">>> Setting up AI Search data source, index, indexer, and skillset"
    echo "" > ./bicep/helpers/ai_search_logs.jsonl

    load_dot_env
    load_dot_env_aoai
    cd ./bicep/helpers

    create_ai_search_data_source
    create_ai_search_index
    create_ai_search_skillset
    create_ai_search_indexer
    echo "<<< Setting up AI Search data source, index, indexer, and skillset completed"
    ;;
  deploy-function)
    echo ">>> Deploying Azure function"
    load_dot_env
    cd ./azure-function
    func azure functionapp publish "${function_app}" \
        --resource-group "${resource_group_name}"
    echo "<<< Deploying Azure function completed"
    ;;
  upload-pdf)
    echo ">>> Uploading PDF"
    load_dot_env

    storage_account_key=$(az storage account keys list \
      --account-name "${storage_account_name}" \
      --resource-group "${resource_group_name}" \
      --output tsv \
      --query "[0].value")

    az storage blob upload \
      --account-name "${storage_account_name}" \
      --container-name "${container_name}" \
      --name "${dest_file_path}" \
      --file "${source_file_path}" \
      --account-key "${storage_account_key}" \
      --overwrite
    echo "<<< Uploading PDF completed"
    ;;
  run-indexer)
    echo ">>> Triggering to run indexer"
    load_dot_env

    base_url="https://${search_service_name}.search.windows.net"

    # Docs: https://learn.microsoft.com/en-us/azure/search/search-howto-run-reset-indexers?tabs=portal
    curl -X POST "${base_url}/indexers/${index_name}-indexer/run?api-version=${api_version}" \
        -H "Content-Type: application/json" \
        -H "api-key: ${search_service_key}" \
        --data ''
    echo ">>> Triggering to run indexer completed"
    ;;
  docker-up)
    bash ./helper.sh docker-build
    bash ./helper.sh docker-run
    bash ./helper.sh docker-exec
    ;;
  deploy)
    bash ./helper.sh create-resource-group
    bash ./helper.sh deploy-bicep
    bash ./helper.sh create-dot-env
    bash ./helper.sh setup-ai-search
    bash ./helper.sh deploy-function
    bash ./helper.sh upload-pdf

    # "Pause script for 60 secondes for Azure Function to prepare the PDF document to be indexed by Azure AI Search indexer."
    sleep 60

    bash ./helper.sh run-indexer
    bash ./helper.sh create-dot-env-demo-app
    bash ./helper.sh install-demo-app-dependencies
    bash ./helper.sh run-demo-app
    ;;
  create-dot-env|cde)
    echo "region=$(get_bicep_output_value region)" > .env
    echo "resource_group=$(get_bicep_output_value resource_group)" >> .env

    search_service_name=$(get_bicep_output_value search_service_name)
    echo "search_service_name=${search_service_name}" >> .env
    base_url="https://${search_service_name}.search.windows.net"
    echo "base_url=${base_url}" >> .env

    echo "search_service_key=$(get_bicep_output_value search_service_key)" >> .env
    echo "subscription_id=$(get_bicep_output_value subscription_id)" >> .env
    echo "storage_account_name=$(get_bicep_output_value storage_account_name)" >> .env
    echo "function_app=$(get_bicep_output_value function_app)" >> .env
    get_blob_sas_token
    ;;
  get-blob-sas|sas)
    get_blob_sas_token
    ;;
  create-dot-env-demo-app)
    configure_demo_app_env_file
    ;;
  install-demo-app-dependencies)
    cd ./demo-app
    pip3 install -r ./requirements.txt
    ;;
  run-demo-app)
    cd ./demo-app
    python3 -m streamlit run ./app.py
    ;;
  docker-build)
    docker build --no-cache -t "${resource_group_name}" .
    ;;
  docker-run)
    docker run -it -d \
      -v .:/home/ubuntu/azure-open-ai-rag-oyd-text-images \
      -v ~/.azure:/home/ubuntu/.azure \
      --name aoai-rag-oyd \
      --workdir /home/ubuntu/azure-open-ai-rag-oyd-text-images/ \
      -p 8501:8501 \
      "${resource_group_name}"
    ;;
  docker-exec)
    docker exec -it "${resource_group_name}" bash
    ;;
  docker-container-stop-remove|dcsr)
    docker stop "${resource_group_name}" && docker rm "${resource_group_name}"
    ;;
  docker-remove-image|dri)
    docker rmi "${resource_group_name}"
    ;;
  test)
    echo "Executing test command"
    ;;
  *)
    # echo "Command \"$@\" doesn't exist. Typo?"
    ;;
esac
