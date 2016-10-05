#!/usr/bin/env bash

set -eu -o pipefail

echo "\$FILEPATH=${FILEPATH}"
echo "\$AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID}"
echo "\$AZURE_RESOURCE_GROUP=${AZURE_RESOURCE_GROUP}"
echo "\$AZURE_STORAGE_ACCOUNT=${AZURE_STORAGE_ACCOUNT}"
echo "\$AZURE_STORAGE_CONTAINER=${AZURE_STORAGE_CONTAINER}"
echo "\$BLOB_NAME=${BLOB_NAME}"
echo "\$AZURE_LOCATION=${AZURE_LOCATION}"

s="--subscription=${AZURE_SUBSCRIPTION_ID}"

# Upload: Ensure resource group exists
rg_exists="$(azure group show "${AZURE_RESOURCE_GROUP}" --json $s || true)"
if [[ -z "${rg_exists}" ]]; then
	echo "upload: creating resource group ${AZURE_RESOURCE_GROUP}"
	azure group create $s -n "${AZURE_RESOURCE_GROUP}" -l "${AZURE_LOCATION}"
fi

# Upload: Ensure Storage Account exists
account_exists=$(azure storage account show "${AZURE_STORAGE_ACCOUNT}" -g "${AZURE_RESOURCE_GROUP}" --json $s | jq '.serviceName' || true)
if [[ -z "${account_exists}" ]]; then
	echo "upload: creating storage account ${AZURE_STORAGE_ACCOUNT}"
	azure storage account create -g "${AZURE_RESOURCE_GROUP}" --location "${AZURE_LOCATION}" --kind Storage --sku-name LRS ${AZURE_STORAGE_ACCOUNT} $s
fi

# Upload: Retrieve Storage Account Key
storage_key=$(azure storage account keys list ${AZURE_STORAGE_ACCOUNT} -g "${AZURE_RESOURCE_GROUP}" --json $s | jq -r '.[0].value')
export AZURE_STORAGE_ACCESS_KEY="${storage_key}"

# Upload: Ensure Storage Container exists
container_exists=$(azure storage container show ${AZURE_STORAGE_CONTAINER} --json | jq -r '.name' || true)
if [[ -z "${container_exists}" ]]; then
	echo "upload: creating storage container ${AZURE_STORAGE_CONTAINER}"
	azure storage container create -p Blob ${AZURE_STORAGE_CONTAINER}
fi

# Upload: Perform the upload
if [[ ! -z "${XPLAT_UPLOAD:-}" ]]; then
	echo "*************** using xplat to upload *****************"
	azure storage blob upload -q $file $container $(basename $file)
else
	echo "*************** using vhd-utils to upload *****************"
	azure-vhd-utils-for-go upload \
		--localvhdpath="${FILEPATH}" \
		--stgaccountname="${AZURE_STORAGE_ACCOUNT}" \
		--stgaccountkey="${AZURE_STORAGE_ACCESS_KEY}" \
		--containername="${AZURE_STORAGE_CONTAINER}" \
		--blobname="${BLOB_NAME}.vhd"
fi

echo "VHD_URL=https://${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net/${AZURE_STORAGE_CONTAINER}/${BLOB_NAME}.vhd"
