## To use this devcontainer:
- First, install Visual Studio Code and Docker.
- Inside the folder `.devcontainer`, copy `.env_template`, rename it to `.env` and put your environment variables there. It is fine to leave some of the variables empty if you do not use them.
- In Visual Studio Code, press `Ctrl + Shift + P`, and choose `Dev Containers: Open Folder in Container...`, then select the root path of this repository.
- Click on `Starting Dev Container (show log)` in the bottom right of the screen to see the build progress, and wait for it to finish.
- Get a GitLab private SSH key from your GitLab account, and put the key into `~/.ssh/` folder
- Create a file named `config` inside the `~/.ssh/` folder with the content below:

```bash
Host gitlab.com
    IdentityFile ~/.ssh/<name of the key>
    IdentitiesOnly yes
```

- Change permission of the files in `~/.ssh/` to Read and Write:

```bash
chmod 600 ~/.ssh/*
```

- In the AWS console, log into your IAM user account and create an access key (if not yet created), and set it directly in VS Code terminal using `aws configure`. Do not save the key anywhere else for security reason!

- The development environment is then ready to use.

## To forward GUI on Windows:
- Install VcXsrv:
    - Download and install VcXsrv from SourceForge.
- Launch VcXsrv (XLaunch) with the following settings:
    - Select "Multiple windows".
    - Start no client.
    - Check "Disable access control".
- Execute this command in Command Prompt to set Environment Variable on Host:
    -  `setx DISPLAY host.docker.internal:0.0`

## For Linux, there must be another way to forward GUI