#!/bin/sh

trap 'rm -f "$TMPFILE"' EXIT
TMPFILE=$(mktemp) || exit 1

IGNORE_IMAGE1="kubernetes longhorn rancher"
IGNORE_IMAGE2=""

for NAME in $IGNORE_IMAGE1; do
    IGNORE_IMAGE2+="${NAME}|"
done
#echo ${IGNORE_IMAGE2:0:-1}

#kubectl get pods --all-namespaces -o jsonpath="{.items[*].spec.containers[*].image}" | \
kubectl get pods -A -o jsonpath="{..imageID}" | tr -s '[[:space:]]' '\n' | \
sort | uniq | grep -iv -E "^.*\/(${IGNORE_IMAGE2:0:-1})" > $TMPFILE


while IFS='\n' read -r LINE;
do
    echo $LINE | cut -d'/' -f1
    if [ $($LINE | cut -d'/' -f1) -eq 'docker.io' ]
    then
done < $TMPFILE

