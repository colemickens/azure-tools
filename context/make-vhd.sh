#!/bin/bash

set -eu -o pipefail

## Basedir
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

set -x
## Pre-requisites
[[ ! -z "${IMAGE_SIZE:-}" ]] || (printf 'export IMAGE_SIZE=10G\n' >&2 && exit 1)

## Temp workdir
tempdir="$(mktemp -d)"
trap "rm -rf \"${tempdir}\"" EXIT
cd "${tempdir}"

## Create empty raw disk
qemu-img create -f raw image.raw "${IMAGE_SIZE}"

## Format as ext4
case "${MKFS_TYPE:-"ext4"}" in
	"ntfs")
		echo "formatting as ntfs"
		mkfs.ntfs -F ./image.raw
		;;
	"xfs")
		echo "formatting as xfs"
		mkfs.xfs ./image.raw
		;;
	"ext4")
		echo "formatting as ext4"
		mkfs.ext4 ./image.raw
		;;
esac

## Convert raw->vhd
qemu-img convert -f raw -o subformat=fixed,force_size -O vpc image.raw image.vhd

## Ensure resource group
export FILEPATH="${tempdir}/image.vhd"
export AZURE_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID}"
export AZURE_RESOURCE_GROUP="${AZURE_RESOURCE_GROUP}"
export AZURE_STORAGE_ACCOUNT="${AZURE_STORAGE_ACCOUNT}"
export AZURE_STORAGE_CONTAINER="${AZURE_STORAGE_CONTAINER}"
export AZURE_LOCATION="${AZURE_LOCATION}"
export BLOB_NAME="${BLOB_NAME:-"data-disk-$(date "+%m%d%y%H%M%S")"}"

${DIR}/upload-file.sh
