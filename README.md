# GitHub Backup

Backup all GitHub repositories using gh

## Prerequisites

- Install [gh](https://github.com/cli/cli#installation)

- Authenticate

    ```bash
    gh auth login
    ```

    Alternatively set `GH_TOKEN` in `backup.sh`

- When using SSH you may have to add the following to your `~/.ssh/config`

    ```bash
    Host github.com
        Hostname ssh.github.com
        Port 443
        User git
    ```

## How to use with MacOS LaunchAgent

1. Update the `ProgramArguments` in `src/com.user.github_backup.plist` to your setup

1. Copy the `.plist` file

    ```bash
    cp src/com.user.github_backup.plist ~/Library/LaunchAgents/
    ```

1. Load the `.plist` file

    ```bash
    launchctl load ~/Library/LaunchAgents/com.user.github_backup.plist
    ```
