# GitHub Backup

Backup all GitHub repositories using gh

## Prerequisites

### Software

- **macOS or Linux** with **Bash** at `/bin/bash` (the Bash 3.2 that ships with macOS is sufficient)

    > The LaunchAgent setup below is macOS-only. On Linux use e.g. cron or a systemd timer instead.

- **git**

    ```bash
    xcode-select --install   # macOS: Command Line Tools
    # or
    brew install git
    ```

- **[GitHub CLI `gh`](https://github.com/cli/cli#installation)**, version **1.10 or newer** (required for `gh repo list --json`)

    ```bash
    brew install gh
    gh --version
    ```

- Standard tools `date`, `sort`, `wc`, `xargs`, `basename` and `mkdir` (preinstalled on macOS and Linux)

### GitHub API authentication

`gh` needs to be authenticated to look up your user and list your repositories (including private ones). Use **one** of the following options:

- **Option A: `gh auth login` (recommended for your own machine)**

    ```bash
    gh auth login
    gh auth status   # verify
    ```

    The token is stored in the macOS Keychain and usually does not expire.

- **Option B: `GH_TOKEN` (for non-interactive setups, e.g. servers)**

    Uncomment the `export GH_TOKEN=...` line in `backup.sh` and insert a token with read access to all repositories you want to back up:

    - **Classic token:** scope `repo` (required to include private repositories)
    - **Fine-grained token:** Repository access *All repositories*, permission *Metadata: Read-only*

    No write permissions are needed. Note that the token is stored in plain text and fine-grained tokens expire, after which the backup fails.

### SSH access for cloning

Repositories are cloned and pulled via **SSH** (`sshUrl`), independently of the API authentication above. Therefore:

1. An SSH key must exist and be added to your GitHub account

    ```bash
    ssh-keygen -t ed25519 -C "your_email@example.com"   # if you don't have a key yet
    gh ssh-key add ~/.ssh/id_ed25519.pub --title "github-backup"
    ```

1. The key must be usable without an interactive passphrase prompt (a LaunchAgent cannot ask for it). On macOS store the passphrase in the Keychain

    ```bash
    ssh-add --apple-use-keychain ~/.ssh/id_ed25519
    ```

    and add to your `~/.ssh/config`

    ```bash
    Host github.com
        AddKeysToAgent yes
        UseKeychain yes
        IdentityFile ~/.ssh/id_ed25519
    ```

1. If port 22 is blocked in your network, connect via port 443 by adding to the same `Host github.com` block

    ```bash
        Hostname ssh.github.com
        Port 443
        User git
    ```

1. Accept GitHub's host key once interactively (otherwise the first non-interactive clone fails)

    ```bash
    ssh -T git@github.com
    # Expected: Hi <username>! You've successfully authenticated, but GitHub does not provide shell access.
    ```

    Repeat this after switching to port 443, as the host key is then stored for `[ssh.github.com]:443`.

### Additional requirements for the macOS LaunchAgent

- **`PATH`:** LaunchAgents start with a minimal `PATH` (`/usr/bin:/bin:/usr/sbin:/sbin`), so a Homebrew-installed `gh` is not found. Uncomment the `export PATH=...` line at the top of `backup.sh`.
- **Full Disk Access:** If the target directory is inside `~/Documents`, `~/Desktop`, `~/Downloads`, iCloud Drive or on an external volume, macOS blocks access from a background job. Either choose a target outside these locations or grant `/bin/bash` access under *System Settings → Privacy & Security → Full Disk Access*.
- **Logged-in user:** LaunchAgents only run while your user is logged in.

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
