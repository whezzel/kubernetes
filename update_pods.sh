#!/bin/sh

trap 'rm -f "$TMPFILE_IMAGE" "$TMPFILE_IMAGEID"' EXIT
TMPFILE_IMAGEID=$(mktemp) || exit 1
TMPFILE_IMAGE=$(mktemp) || exit 1

IGNORE_IMAGE1="kubernetes longhorn rancher"
IGNORE_IMAGE2=""

docker_token () {
    # requires `jq` to be installed
    TOKEN=$(curl --silent "https://auth.docker.io/token?scope=repository:$IMAGE:pull&service=registry.docker.io"  | jq -r '.token')
}

container_image () {
kubectl get pods -A -o jsonpath="{.items[*].status.containerStatuses[*].image}" | \
#kubectl get pods -A -o jsonpath="{..imageID}" | \
tr -s '[[:space:]]' '\n' | \
sort | uniq | grep -iv -E "^.*\/(${IGNORE_IMAGE2:0:-1})" > $TMPFILE_IMAGE
}

container_imageid () {
kubectl get pods -A -o jsonpath="{.items[*].status.containerStatuses[*].imageID}" | \
#kubectl get pods -A -o jsonpath="{..imageID}" | \
tr -s '[[:space:]]' '\n' | \
sort | uniq | grep -iv -E "^.*\/(${IGNORE_IMAGE2:0:-1})" > $TMPFILE_IMAGEID
}

container_imageinfo () {
kubectl get pods -A -o jsonpath="{.items[*].status.containerStatuses[*]['image', 'imageID']}"
}

for NAME in $IGNORE_IMAGE1; do
    IGNORE_IMAGE2+="${NAME}|"
done

echo ${IGNORE_IMAGE2:0:-1}

container_image
cat  $TMPFILE_IMAGE
echo
container_imageid
cat $TMPFILE_IMAGEID

#kubectl get pods -A --field-selector \
#metadata.namespace!=kube-system,\
#metadata.namespace!=kube-public,\
#metadata.namespace!=kube-node-lease,\
#metadata.namespace!=longhorn-system \
#-o jsonpath="{.items[*].status.containerStatuses[*]['image', 'imageID']}" | \
#tr -s '[[:space:]]' '\n'

while IFS='\n' read -r LINE;
do
    #echo $LINE | cut -d'/' -f1
    if [[ $LINE == *docker.io* ]]
    then
        #IMAGE=`$LINE | cut -d'/' -f2,3 | cut -d'@' -f1`
        IMAGE=$(cut -d'/' -f2,3 <<< $LINE | cut -d'@' -f1)
        echo $IMAGE
        #docker_token
        #echo $TOKEN
        #TAG=latest
        #curl -s --header "Accept: application/vnd.docker.distribution.manifest.list.v2+json" --header "Authorization: Bearer ${token}" "https://registry-1.docker.io/v2/$image/manifests/$tag" | jq -r '.manifests|.[]| "\(.digest) \(.platform.architecture) \(.platform.variant)"'
    else
        echo "not using docker.io"
    fi
done < $TMPFILE_IMAGE




