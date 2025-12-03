#!/bin/sh

cat source/eXist-db/controller.xql | sed -n -e 's/if (matches($exist:path, '"'"'\([^'"'"']*\)'"'"'.*/\1/gp'

