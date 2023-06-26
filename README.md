# Please CLI by TNG Technology Consulting

An [AI helper script to create CLI commands](https://github.com/TNG/please-cli/).

## Usage

```bash
please <command description>
```

This will call GPT to generate a Linux command based on your input.

### Examples

![Demo](resources/demo.gif)

```bash
please list all files smaller than 1MB in the current folder, \
         sort them by size and show their name and line count
💡 Command:
  find . -maxdepth 1 -type f -size -1M -exec wc -l {} + | sort -n -k1'

❗ What should I do? [use arrow keys or initials to navigate]
> [I] Invoke   [C] Copy to clipboard   [Q] Ask a question   [A] Abort
```

You may then:

- Invoke the command directly (pressing I)
- Copy the command to the clipboard (pressing C)
- Ask a question about the command (pressing Q)
- Abort (pressing A)

```bash

### Parameters
- `-e` or `--explanation` will explain the command for you
- `-l` or `--legacy` will use the GPT3.5 AI model instead of GPT4 (in case you don't have API access to GPT4)
- `--debug` will display additional output
- `-a` or `--api-key` will store your API key in the local keychain
- `-v` or `--version` will show the current version
- `-h` or `--help` will show the help message
```

## Installation

### brew

Using Homebrew (ugrades will be available via `brew upgrade please`)

```
brew tap TNG/please
brew install please
```

### apt

Using apt (upgrades will be available via `apt upgrade please`)

```bash
curl -sS https://tng.github.io/apt-please/public_key.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/please.gpg > /dev/null
echo "deb https://tng.github.io/apt-please/ ./" | sudo tee -a /etc/apt/sources.list
sudo apt-get update

sudo apt-get install please
```

### nix

```bash
git clone https://github.com/TNG/please-cli.git
cd please-cli
nix-env -i -f .
```

Using Nix Flakes

```bash
nix run github:TNG/please-cli
```

### dpkg

Manual upgrades

```bash
wget https://tng.github.io/apt-please/please.deb
sudo dpkg -i please.deb
sudo apt-get install -f
```

### arch
```bash
git clone https://github.com/TNG/please-cli.git
makepkg --clean --install
```

### Manually from source

Just copying the script (manual upgrades)

```bash
wget https://raw.githubusercontent.com/TNG/please-cli/main/please.sh
sudo cp please.sh /usr/local/bin/please
sudo chmod +x /usr/local/bin/please

# Install jq and (if on Linux) secret-tool as well as xclip using the package manager of your choice
```

## Prerequisites

You need an OpenAI API key. You can get one here: https://beta.openai.com/. Once logged in, click your account in the top right corner and select "View API Keys". You can then create a new key using the "Create new secret key" button.

The API key needs to be set:

- either via an environment variable `OPENAI_API_KEY`,
- or via a keychain entry `OPENAI_API_KEY` (macOS keychain and secret-tool on Linux are supported)

The easiest way to set the API Key is to use the `please` command itself to do so:

```bash
please -a
```

This will set the API key in the keychain of your operating system (secret-tool on Linux, macOS keychain on MacOS).

You can also set the API key via an environment variable, run

```bash
export OPENAI_API_KEY=<YOUR_API_KEY>
```

To store your API key yourself using secret-tool, run

```bash
secret-tool store --label="OPENAI_API_KEY" username "${USER}" key_name OPENAI_API_KEY apiKey "${apiKey}"
```

To store your API key using macOS keychain, run

```bash
security add-generic-password -a "${USER}" -s OPENAI_API_KEY -w "${apiKey}"
```

## Troubleshooting

If you receive the following error message:

```bash
Error: Received HTTP status 404
The model: gpt-4 does not exist
```

The API key you are using is not authorized to use GPT-4. You may also want to use the `--legacy` flag to use GPT-3.5 instead.
You can also apply for GPT4 API access here: https://openai.com/waitlist/gpt-4-api

## License

Please CLI is published under the Apache License 2.0, see http://www.apache.org/licenses/LICENSE-2.0 for details.

Copyright 2023 TNG Technology Consulting GmbH
