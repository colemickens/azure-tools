#!/bin/sh
set -eux -o pipefail

apk add --update --no-cache git build-base wget jq ca-certificates parallel vim curl go e2fsprogs xfsprogs ntfs-3g-progs

apk add qemu-img --update-cache --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/main/ --allow-untrusted

## Install azure-xplat-cli
npm install -g azure-cli
azure telemetry --disable
rm -rf /tmp/npm*

## Install azure-vhd-utils
export GOPATH=/gopath
mkdir -p "${GOPATH}"
go get github.com/Microsoft/azure-vhd-utils-for-go
cp "${GOPATH}/bin/azure-vhd-utils-for-go" "/usr/local/bin/"
rm -rf "${GOPATH}"

## Enable azure completion
azure --completion >> ~/azure.completion.sh
echo 'source ~/azure.completion.sh' >> ~/.bash_profile

## Cleanup
apk del --purge build-base go
