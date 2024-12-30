# Upload Files from a Scanner or from Nextcloud to Paperless-ngx
> **Note**: Ok guys, I keep this one short, since it's not the focus of this repository. Please also **do not open any issues related to the upload topic**, I will close them immediately.

At first, this is my setup:
![](documentation/my-setup_diagram-2.drawio.svg)

The key here is the ProFTP-Container:
```yaml
version: "3"

services:
  ftp-upload:
    image: kibatic/proftpd
    network_mode: "host"
    restart: unless-stopped
    environment:
      FTP_LIST: "$FTP_UPLOAD_USER:$FTP_UPLOAD_PASSWORD"
      PASSIVE_MIN_PORT: 50000
      PASSIVE_MAX_PORT: 50100
    volumes:
      - "/mnt/data/paperless_data/consume:/home/$FTP_UPLOAD_USER"
```
Of course environment `FTP_UPLOAD_USER` and `FTP_UPLOAD_PASSWORD` must be set.
More details about that container can be found in the [official repository](https://github.com/kibatic/docker-proftpd).


## Connection

**Scanner**: As you can see from the diagram, the scanner is transferring scanned PDFs directly. Just configure the FTP-User and FTP-Password, which should be available for like all network scanners.

**Nextcloud**: I mounted the FTP-server as **[External Storage](https://docs.nextcloud.com/server/latest/admin_manual/configuration_files/external_storage_configuration_gui.html)** from the Paperless User account and also shared this one with other users or groups with **read-write permissions**. This has several advantages:
1. It enables to simply drop files in that `Paperless_consume`-Folder in Nextcloud to push it to Paperless-ngx
2. I don't need to make the FTP-server public accessible when I want to scan files with a mobile app from a remote location. I can use the existing public accessible Nextcloud connection to send files to the `Paperless_consume`-Folder. Nextcloud will then hand this over to Paperless-ngx and the consume-process will be triggered.
3. Of course I could also upload via VPN and FTP, but never underestimate the WAF (Woman Acceptance Factor)! 😂
