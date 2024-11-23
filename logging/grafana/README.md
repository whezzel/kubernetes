# Volume Setup

### Scale pod to 0 to terminate pod and detach longhorn volume

`kubectl -n logging scale --replicas 0 deployment <deployment>`

### Mount longhorn volume

`mkdir /mnt/temp`

`mount -o loop /dev/longhorn/grafana /mnt/temp/`

### Copy existing data to volume
or
### Download default grafana.ini

`wget -O /mnt/temp/grafana/grafana.ini https://raw.githubusercontent.com/grafana/grafana/main/conf/defaults.ini`

### Set Permissions

`chown -R 472:root /mnt/temp/{data,grafana,logs}`

### Unmount longhorn volume

`umount /mnt/temp`

### Scale pod to 1 to start pod and attach longhorn volume

`kubectl -n logging scale --replicas 1 deployment <deployment>`
