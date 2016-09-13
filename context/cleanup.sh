#!/usr/bin/env bash

set -eou -o pipefail

FILTER="${1}"

if [[ -z "${AZURE_SUBSCRIPTION_ID}" ]]; then
	echo "AZURE_SUBSCRIPTION_ID must be set!"
	exit -1
fi

rgs=($(azure group list --subscription="${AZURE_SUBSCRIPTION_ID}" --json | jq -r ".[].name | select(contains(\"${FILTER}\"))" -))
if ! (( ${#rgs[@]} > 0 )); then
	echo "There were no matching groups. Exiting!"
	exit 0
fi

echo "DELETE: ${rgs[@]}"
echo "SUBSCRIPTION: ${AZURE_SUBSCRIPTION_ID}"
echo -n "CONFIRM ('yes' proceeds, everything else exits): "
read -r CONFIRM
if [[ "${CONFIRM}" != "yes" ]]; then
	echo "Only 'yes' will allow deletion! Exiting!"
	exit -1
fi

parallel -j 8 --progress timeout -t 5 azure group delete --quiet --subscription "${AZURE_SUBSCRIPTION_ID}" ::: ${rgs[@]}
