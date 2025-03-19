# Please CLI (Ollama Fork)

This is a fork of the original [please-cli](https://github.com/TNG/please-cli/) project with the following changes:
- Replaced openai related structure with ollama specific implementation
- Removed any support for openai requests including getting rid of openai api keys
- fixed a ui bug possibly caused by my changes

The original copyright and NOTICE file are retained in this repository.

## Usage

```bash
please <command description>
```

This will call a local model through ollama to generate a Linux command based on your input.

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
- `--debug` will display additional output
- `-m` or `--model` will query local ollama server with the specified model
- `-v` or `--version` will show the current version
- `-h` or `--help` will show the help message
```

## Installation

### Manually from source

Just copying the script (manual upgrades)

```bash
wget https://raw.githubusercontent.com/TNG/please-cli/main/please.sh
sudo cp please.sh /usr/local/bin/please
sudo chmod +x /usr/local/bin/please

# Install jq and (if on Linux) secret-tool as well as xclip using the package manager of your choice
```

## Prerequisites

You need an Ollama server running on your local machine, but you can obviously change the ollama_url to 

## Configuration

You can use the more specific environment variables if you do not want to change OpenAI settings globally:
* `PLEASE_CHAT_MODEL` - The local chat model to use
* `OLLAMA_URL` - The server to send /api/chat the requests to

## Troubleshooting

If you receive the following error message:

```bash
Error: Received HTTP status 404
```

There probably is an issue with your base URL. Please check the Ollama Url in your environment variables.

## Choosing a model

I found that the llama3.2 (3b) parameter works fairly quick with my older gpu and gives good results. 
I initially tried with deepseek-r1:7b but the reasoning takes too long and would be annoying to parse.

## License

Please CLI is published under the Apache License 2.0, see http://www.apache.org/licenses/LICENSE-2.0 for details.
