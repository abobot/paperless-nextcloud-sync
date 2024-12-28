# Paperless-ngx to Nextcloud Real-Time Synchronization via WebDAV

<!-- Purpose of this repository and its offerings
Synchronization **only in one direction!**

Illustration of my setup for better understanding, based on `documentation\my-setup_diagram.drawio`.

Additional information on related topics in my setup, such as Nextcloud settings, ProFTP for Nextcloud-to-Paperless file transfer, and mobile scanning, is available. -->



## Installation and Setup
1. Open the shell on the server where Paperless is running and execute: <br>
   ```
   git clone https://github.com/Flo-R1der/paperless-nextcloud-sync.git
   ```
2. Navigate to the repository directory (typically `cd paperless-nextcloud-sync`) and execute: <br>
   ```
   docker build --file ./paperless-nextcloud-sync.Dockerfile --tag paperless-nextcloud-sync .
   ```
3. Add the container to your Paperless instance, preferably via **Docker Compose** or **[Portainer Stack](https://docs.portainer.io/user/docker/stacks/edit)**.
    - You can use and edit the following block:
        ```yaml
        version: "3"

        services:
          nc-sync:
            image: paperless-nextcloud-sync
            volumes:
              - "/mnt/data/paperless_data/Document_Library/documents/archive:/mnt/source:ro"
            environment:
              WEBDRIVE_URL: $NEXTCLOUD_URL
              WEBDRIVE_USER: $NEXTCLOUD_USER
              WEBDRIVE_PASSWORD: $NEXTCLOUD_PASSWORD
              LC_ALL: de_DE.UTF-8
              TZ: Europe/Berlin
            privileged: true
            devices:
              - "/dev/fuse"
        ```
        > **Note**: `privileged: true` and `devices: "/dev/fuse"` are mandatory for WebDAV mounts.

    - Fill in the `WEBDRIVE_URL`, `WEBDRIVE_USER`, and `WEBDRIVE_PASSWORD` values.
        - Optional: Use the environment variable `WEBDRIVE_PASSWORD_FILE` instead of `WEBDRIVE_PASSWORD` if you want to utilize Docker secrets.
        - Optional: Define mounting options using `FOLDER_USER`, `FOLDER_GROUP`, `ACCESS_DIR`, and `ACCESS_FILE`. This can be useful if you also want the WebDAV drive mapped to a mount point on the Docker host.

    - Restart the Paperless instance to activate the container.

4. Verify the container is running and check the container logs:
    - Use `docker logs --follow <container-name>` (replace `<container-name>` with your container's name) or utilize the [Portainer Log Viewer](https://docs.portainer.io/user/docker/containers/logs).

        <details>
        <summary>Example screenshot</summary>
        <img src="documentation\container-logs_short-example.png" width=680px/>
        </details>

        Alternatively, compare the output to the more detailed <a href="documentation\container-logs_example.txt">log example</a>, if necessary.



## Startup
On the first run, always inspect the container logs. The logs should include the following:
1. The container sets locales if `LC_ALL` is configured with a value other than `en_US.UTF-8`. This ensures support for non-ASCII characters in filenames.
2. The container validates mandatory environment variables (`WEBDRIVE_URL`, `WEBDRIVE_USER`, `WEBDRIVE_PASSWORD`). If any are missing, the container exits with code 1.
3. If configured correctly, the WebDAV drive (Nextcloud) is mounted via `davfs`. Errors during mounting will stop the container with exit code 1.
4. Upon successful mounting:
    - **Initial synchronization** and **file-watcher** are started to detect changes and keep Nextcloud synchronized with Paperless.

        <details>
        <summary>Technical details post-WebDAV mount</summary>

        - Sets a `trap` to unmount the drive properly when a stop signal is received.
        - Initiates `sync.sh` for initial synchronization to update Nextcloud in the background.
            > **Note**: While `rsync` could achieve similar results, it has caused file deletions during initial synchronization in my tests. My script avoids this issue, though some errors are still logged. Please share any better solutions!
        - Configures a file watcher to monitor changes by Paperless:
            - **CREATE**: Copies new files/folders from Paperless to Nextcloud.
            - **MODIFY**: Updates files in Nextcloud, creating new document versions (e.g., rotated pages, new OCR runs, etc.).
            - **DELETE**: Deletes corresponding files in Nextcloud.
            - **MOVED_FROM** and **MOVED_TO**: Handles file renaming or moving, using paths provided in these events.
        </details>



## Expected Results
1. When started, the **health check** verifies WebDAV mounting and file watcher operation. If successful, the container is marked **healthy**.
    <details>
    <summary>Portainer screenshot: Container is <b>started and healthy</b></summary>
    <img src="documentation\paperless-stack_portainer.png" width=900px/>
    </details>
    <br>

2. After successful startup (indicated in logs by a `=====` line):
    - The file watcher waits for events and synchronizes Nextcloud accordingly (refer to the technical details in point 4 from the Startup section).
    - Initial synchronization compares source and Nextcloud directories to sync changes made while the container was offline. This process also uploads existing files during the first run.
    - Completion of initial synchronization is logged, enclosed by `-----` lines.
        <details>
        <summary>Example screenshot</summary>
        <img src="documentation\container-logs_short-example.png" width=680px/>
        </details>

        Alternative: Refer to the detailed <a href="documentation\container-logs_example.txt">log example</a>, if necessary. For this example also take into account the technical details in point 4 from the Startup section.



## Open Topics
- Replace initial synchronization with a better solution. My tests with `rsync` caused file deletions during synchronization, which my script avoids but still produces error messages (see [log example](documentation\container-logs_example.txt), lines 20-24). **Please open issues only if you have a suitable solution!**
- Publish Docker image on GHCR and Docker Hub.

<br>

## Like My Work?
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/I3I4160K4Y)
