# Volume Setup

1) Scale pod to 0 to terminate pod and detach longhorn volume

    ```bash
    kubectl -n logging scale --replicas 0 deployment <deployment>
    ```

2) Mount longhorn volume

    ```bash
    mkdir /mnt/temp
    mount -o loop /dev/longhorn/grafana /mnt/temp/
    ```

3) Copy existing data to volume or Download default grafana.ini

    ```bash
    wget -O /mnt/temp/grafana/grafana.ini https://raw.githubusercontent.com/grafana/grafana/main/conf/defaults.ini
    ```

4) Set Permissions

    ```bash
    chown -R 472:root /mnt/temp/{data,grafana,logs}
    ```

5) Unmount longhorn volume

    ```bash
    umount /mnt/temp
    ```

6) Scale pod to 1 to start pod and attach longhorn volume

    ```bash
    kubectl -n logging scale --replicas 1 deployment <deployment>
    ```
