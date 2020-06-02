#!/usr/bin/env bash
version="$0 0.0.1"

set -o errexit
set -o pipefail

# CONFIGURATION
deps=('ansible' 'ansible-playbook')
script_path="$( cd "$(dirname "$0")" ; pwd -P )"
inventory_dir="${script_path}/inventory"
pb_dir="${script_path}/pb"
ansible_main_dir="${script_path}"
secrets_inventory="--inventory=${inventory_dir}/secrets_inventory.ini"
inventory="--inventory=${inventory_dir}/inventory.ini"

check_deps() {
  # Check if a binary is available and export a global
  # variable based on the program name
  #
  # Args:
  # $1:  Program name

  local _d=$(echo __${1^^} | sed 's/-/_/g')
  eval "$_d"="$(which $1 2>/dev/null)"

  if [[ -z "${!_d}" ]]; then
    echo "Please install '$1' first!"
    exit 3
  fi
}

usage() {
  echo "Usage examples:"
  echo
  echo "$0 --install"
  echo "$0 --start"
  echo
  echo "Options:"
  echo "  -i, --install                                               : installs all jitsi related services and docker containers"
  echo "  -u, --start                                                 : starts all jitsi related services and docker containers" #todo
  echo "  -s, --stop                                                  : stops all jitsi related services and docker containers" #todo
  echo " -rs, --restart                                               : starts all jitsi related services and docker containers" #todo
  echo "  -d, --down                                                  : down all jitsi related services and docker containers" #todo
  echo "  -r, --remove                                                : resets the host and removes everything jitsi related"
  echo "      --dry-run                                               : Do not make any changes, just print commands" # todo
  echo "  -v, --version                                               : Show program version"
  echo "      --debug                                                 : Enable debug output"
}

install_jitsi_server() {
  ${dry} ${__ANSIBLE_PLAYBOOK} ${inventory} ${secrets_inventory} --become --ask-vault-pass $verbose "${pb_dir}/install.yml"
}

start_jitsi_server() {
  ${dry} ${__ANSIBLE_PLAYBOOK} ${inventory} ${secrets_inventory} --become --ask-vault-pass $verbose "${pb_dir}/start.yml"
}

restart_jitsi_server() {
  ${dry} ${__ANSIBLE_PLAYBOOK} ${inventory} ${secrets_inventory} --become --ask-vault-pass $verbose "${pb_dir}/restart.yml"
}

down_jitsi_server() {
  ${dry} ${__ANSIBLE_PLAYBOOK} ${inventory} ${secrets_inventory} --become --ask-vault-pass $verbose "${pb_dir}/down.yml"
}

stop_jitsi_server() {
  ${dry} ${__ANSIBLE_PLAYBOOK} ${inventory} ${secrets_inventory} --become --ask-vault-pass $verbose "${pb_dir}/stop.yml"
}

remove_jitsi_server() {
  ${dry} ${__ANSIBLE_PLAYBOOK} ${inventory} ${secrets_inventory} --become --ask-vault-pass $verbose "${pb_dir}/remove.yml"
}

for prog in "${deps[@]}"; do
  check_deps "$prog"
done

cd "${ansible_main_dir}"

print_usage=0; debug=0; dry_run=0; verbose=""
[[ $# -eq 0 ]] && usage
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--install)
      install=1
    ;;
    -rs|--restart)
      restart=1
    ;;
    -u|--start)
      start=1
    ;;
    -s|--stop)
      stop=1
    ;;
    -d|--down)
      down=1
    ;;
    -r|--remove)
      remove=1
    ;;
    --debug)
      set -x
      verbose="-vvv"
    ;;
    -v|--version)
      echo $version
      exit 0
    ;;
    --dry-run) # todo
      dry="echo"
    ;;
    -h|--help)
      usage
    ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 3
    ;;
  esac
  shift || true
done

if [[ $install -eq 1 ]]; then
  install_jitsi_server
fi

if [[ $start -eq 1 ]]; then
  start_jitsi_server
fi

if [[ $stop -eq 1 ]]; then
  stop_jitsi_server
fi

if [[ $restart -eq 1 ]]; then
  restart_jitsi_server
fi

if [[ $down -eq 1 ]]; then
  down_jitsi_server
fi

if [[ $remove -eq 1 ]]; then
  remove_jitsi_server
fi
