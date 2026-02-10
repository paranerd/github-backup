# GitHub Backup

Backup all GitHub repositories using gh

## Prerequisites

- Have `gh` installed

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
