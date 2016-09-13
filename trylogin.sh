#!/bin/sh

if ! azure account show &>/dev/null ; then
	azure login
	azure account list
fi
