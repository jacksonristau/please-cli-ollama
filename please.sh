#!/usr/bin/env bash

set -uo pipefail

model=${PLEASE_CHAT_MODEL:-'llama3.2'}
ollama_url=${OLLAMA_URL:-'http://localhost:11434'}

options=("[I] Invoke" "[C] Copy to clipboard" "[Q] Ask a question" "[A] Abort" )
number_of_options=${#options[@]}

explain=0
debug_flag=0

initialized=0
selected_option_index=-1

yellow='\e[33m'
cyan='\e[36m'
black='\e[0m'

lightbulb="\xF0\x9F\x92\xA1"
exclamation="\xE2\x9D\x97"
questionMark="\x1B[31m?\x1B[0m"
checkMark="\x1B[31m\xE2\x9C\x93\x1B[0m"

fail_msg="echo 'I do not know. Please rephrase your question.'"

declare -a qaMessages=()

check_args() {
  while [[ $# -gt 0 ]]; do
    case "${1}" in
      -e|--explanation)
        explain=1
        shift
        ;;
      --debug)
        debug_flag=1
        shift
        ;;
      -m|--model)
        if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
          model="$2"
          shift 2
        else
          echo "Error: --model requires a gpt model"
          exit 1
        fi
        ;;
      -v|--version)
        display_version
        exit 0
        ;;
      -h|--help)
        display_help
        exit 0
        ;;
      *)
        break
        ;;
    esac
  done

  # Save remaining arguments to a string
  commandDescription="$*"
}

display_version() {
  echo "Please vVERSION_NUMBER"
}

display_help() {
  echo "Please - a simple script to translate your thoughts into command line commands using GPT"
  echo "Usage: $0 [options] [input]"
  echo
  echo "Options:"
  echo "  -e, --explanation    Explain the command to the user"
  echo "      --debug          Show debugging output"
  echo "  -m, --model          Specify the exact LLM model for the script"
  echo "  -v, --version        Display version information and exit"
  echo "  -h, --help           Display this help message and exit"
  echo
  echo "Input:"
  echo "  The remaining arguments are used as input to be turned into a CLI command."
  echo
}


debug() {
    if [ "$debug_flag" = 1 ]; then
        echo "DEBUG: $1" >&2
    fi
}

# this is where the http request is built 
get_command() {
  role="You translate the given input into a Linux command. You may not use natural language, but only a Linux shell command as an answer.
  Do not use markdown. Do not quote the whole output. If you do not know the answer, answer with \\\"${fail_msg}\\\"."

  payload=$(printf %s "$commandDescription" | jq --slurp --raw-input --compact-output '{
    model: "'"$model"'",
    messages: [{ role: "system", content: "'"$role"'" }, { role: "user", content: . }],
    stream: false
  }')

  debug "Sending request to Ollama API: ${payload}"

  perform_ollama_request
  command="${message}"
}

explain_command() {
  if [ "${command}" = "$fail_msg" ]; then
    explanation="There is no explanation because there was no answer."
  else
    prompt="Explain the step of the command that answers the following ${command}: ${commandDescription}\n. Be precise and succinct."

    payload=$(printf %s "$prompt" | jq --slurp --raw-input --compact-output '{
      max_tokens: 100,
      model: "'"$model"'",
      messages: [{ role: "user", content: . }],
      stream: false
    }')

    perform_ollama_request
    explanation="${message}"
  fi
}

perform_ollama_request() {
  completions_url="${ollama_url}/api/chat"
  IFS=$'\n' read -r -d '' -a result < <(curl "${completions_url}" \
       -s -w "\n%{http_code}" \
       -H "Content-Type: application/json" \
       -H "Accept-Encoding: identity" \
       -d "${payload}" \
       --silent)
  debug "Response:\n${result[*]}"
  length="${#result[@]}"
  httpStatus="${result[$((length-1))]}"

  length="${#result[@]}"
  response_array=("${result[*]:0:$((length-1))}")
  response="${response_array[*]}"

  if [ "${httpStatus}" -ne 200 ]; then
    echo "Error: Received HTTP status ${httpStatus} while trying to access ${completions_url}"
    echo "${response}"
    exit 1
  else
    message=$(echo "${response}" | jq '.message.content' --raw-output)
  fi
}

print_option() {
  # shellcheck disable=SC2059
  printf "${lightbulb} ${cyan}Command:${black}\n"
  echo "  ${command}"
  if [ "${explain}" -eq 1 ]; then
    echo ""
    echo "${explanation}"
  fi
}

choose_action() {
  initialized=0
  selected_option_index=-1

  echo ""
  # shellcheck disable=SC2059
  printf "${exclamation} ${yellow}What should I do? ${cyan}[use arrow keys or initials to navigate]${black}\n"

  while true; do
    display_menu

    read -rsn1 input
    # Check for arrow keys and 'Enter'
    case "$input" in
      $'\x1b')
        read -rsn1 tmp
        if [[ "$tmp" == "[" ]]; then
          read -rsn1 tmp
          case "$tmp" in
            "D") # Right arrow
              selected_option_index=$(( (selected_option_index - 1 + number_of_options) % number_of_options ))
              ;;
            "C") # Left arrow
              selected_option_index=$(( (selected_option_index + 1) % number_of_options ))
              ;;
          esac
        fi
        ;;
      "i"|"I")
        selected_option_index=0
        display_menu
        break
        ;;

      "c"|"C")
        selected_option_index=1
        display_menu
        break
        ;;
      "q"|"Q")
        selected_option_index=2
        display_menu
        break
        ;;
      "a"|"A")
        selected_option_index=3
        display_menu
        break
        ;;

      "") # 'Enter' key
        if [ "$selected_option_index" -ne -1 ]; then
          break
        fi
        ;;
    esac
  done
}

display_menu() {
  if [ $initialized -eq 1 ]; then
    # Go up 1 line
    printf "\033[1A" "1"
    printf "\033[2K"
  else
    initialized=1
  fi

  index=0
  for option in "${options[@]}"; do
    (( index == selected_option_index )) && marker="${cyan}>${black}" || marker=" "
    # shellcheck disable=SC2059
    printf "$marker $option "
    (( ++index ))
  done
  printf "\n"
}

act_on_action() {
  if [ "$selected_option_index" -eq 0 ]; then
    echo "Executing ..."
    echo ""
    execute_command
  elif [ "$selected_option_index" -eq 1 ]; then
    echo "Copying to clipboard ..."
    copy_to_clipboard
  elif [ "$selected_option_index" -eq 2 ]; then
    ask_question
  else
    exit 0
  fi
}

execute_command() {
    save_command_in_history
    eval "${command}"
}

save_command_in_history() {
  # Get the name of the shell
  shell=$(basename "$SHELL")

  # Determine the history file based on the shell
  case "$shell" in
      bash)
          histfile="${HISTFILE:-$HOME/.bash_history}"
          ;;
      zsh)
          histfile="${HISTFILE:-$HOME/.zsh_history}"
          ;;
      fish)
          # fish doesn't use HISTFILE, but uses a fixed location
          histfile="$HOME/.local/share/fish/fish_history"
          ;;
      ksh)
          histfile="${HISTFILE:-$HOME/.sh_history}"
          ;;
      tcsh)
          histfile="${HISTFILE:-$HOME/.history}"
          ;;
      *)
          ;;
  esac

  if [ -z "$histfile" ]; then
    debug "Could not determine history file for shell ${shell}"
  else
    debug "Saving command ${command} to file ${histfile}"
    echo "${command}" >> "${histfile}"
  fi
}

copy_to_clipboard() {
  case "$(uname)" in
    Darwin*) # macOS
      echo -n "${command}" | pbcopy
      ;;
    Linux*)
      if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
        echo -n "${command}" | wl-copy --primary
      else
        if command -v xclip &> /dev/null; then
          echo -n "${command}" | xclip -selection clipboard
        else
          echo "xclip not installed. Exiting."
          exit 1
        fi
      fi
      ;;
    *)
      echo "Unsupported operating system"
      exit 1
      ;;
  esac
}

init_questions() {
  systemPrompt="You will give answers in the context of the command \"${command}\" which is a Linux bash command related to the prompt \"${commandDescription}\". Be precise and succinct, answer in full sentences, no lists, no markdown."
  escapedPrompt=$(printf %s "${systemPrompt}" | jq -srR '@json')

  qaMessages+=("{ \"role\": \"system\", \"content\": ${escapedPrompt} }")
}

ask_question() {
  echo ""
  # shellcheck disable=SC2059
  printf "${questionMark} ${cyan}What do you want to know about this command?${black}\n"
  read -r question
  answer_question_about_command

  echo "${answer}"

  # shellcheck disable=SC2059
  printf "${checkMark} ${answer}\n"

  choose_action
  act_on_action
}

answer_question_about_command() {
  prompt="${question}"
  escapedPrompt=$(printf %s "${prompt}" | jq -srR '@json')
  qaMessages+=("{ \"role\": \"user\", \"content\": ${escapedPrompt} }")
  messagesJson='['$(join_by , "${qaMessages[@]}")']'

  payload=$(jq --null-input --compact-output --argjson messagesJson "${messagesJson}" '{
    max_tokens: 200,
    model: "'"$model"'",
    messages: $messagesJson
  }')

  perform_ollama_request

  answer="${message}"
  escapedAnswer=$(printf %s "$answer" | jq -srR '@json')
  qaMessages+=("{ \"role\": \"assistant\", \"content\": ${escapedAnswer} }")
}

function join_by {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

function main() {
  if [ $# -eq 0 ]; then
    input=("-h")
  else
    input=("$@")
  fi

  check_args "${input[@]}"

  get_command
  if [ "${explain}" -eq 1 ]; then
    explain_command
  fi

  print_option

  if test "${command}" = "${fail_msg}"; then
    exit 1
  fi

  init_questions
  choose_action
  act_on_action
}

# Only call main if the script is not being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi