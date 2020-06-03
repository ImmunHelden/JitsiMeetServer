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
  echo "  -r, --remove                                                : resets the host and removes everything jitsi related"
  echo "  -u, --up                                                    : starts all jitsi related services and docker containers"
  echo "  -d, --down                                                  : down all jitsi related services and docker containers"
  echo "      --reset                                                 : runs all roles successively to completly reinstall and startup the jitsi services"
  echo " -cu, --creatuser                                             : create a new user"
  echo "      --username <username>                                   : the username parameter for a new user"
  echo "      --password <password>                                   : the password parameter for a new user"
  echo " -rs, --restart                                               : starts all jitsi related services and docker containers"
  echo "      --dry-run                                               : Do not make any changes, just print commands"
  echo "  -v, --version                                               : Show program version"
  echo "      --debug                                                 : Enable debug output"
}

install_jitsi_server() {
  echo "install dependencies and configure host"
  ${dry} ${__ANSIBLE_PLAYBOOK} ${inventory} ${secrets_inventory} --become --ask-vault-pass $verbose "${pb_dir}/install.yml"
}

up_jitsi_server() {
  echo "start service container"
  ${dry} ${__ANSIBLE_PLAYBOOK} ${inventory} ${secrets_inventory} --become --ask-vault-pass $verbose "${pb_dir}/up.yml"
}

restart_jitsi_server() {
  echo "reinitialize container services"
  ${dry} ${__ANSIBLE_PLAYBOOK} ${inventory} ${secrets_inventory} --become --ask-vault-pass $verbose "${pb_dir}/restart.yml"
}

down_jitsi_server() {
  echo "shut down container services"
  ${dry} ${__ANSIBLE_PLAYBOOK} ${inventory} ${secrets_inventory} --become --ask-vault-pass $verbose "${pb_dir}/down.yml"
}

remove_jitsi_server() {
  echo "reset host"
  ${dry} ${__ANSIBLE_PLAYBOOK} ${inventory} ${secrets_inventory} --become --ask-vault-pass $verbose "${pb_dir}/remove.yml"
}

reset_jitsi_server() {
  echo "reset host, reinstall and bootup service container"
  ${dry} ${__ANSIBLE_PLAYBOOK} ${inventory} ${secrets_inventory} --become --ask-vault-pass $verbose "${pb_dir}/reset.yml"
}

create_new_user() {
  echo "create new user"
  local _username="--extra-vars new_user=$1"
  local _password="--extra-vars new_password=$2"

  ${dry} ${__ANSIBLE_PLAYBOOK} ${inventory} ${secrets_inventory} --become --ask-vault-pass $verbose "${pb_dir}/new_user.yml" ${_username} ${_password}
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
    --reset)
      reset=1
    ;;
    -u|--up)
      up=1
    ;;
    -d|--down)
      down=1
    ;;
    -r|--remove)
      remove=1
    ;;
    --createuser)
      createuser=1
    ;;
    --username)
      username=${2}
      shift
    ;;
    --password)
      password=${2}
      shift
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

if [[ $up -eq 1 ]]; then
  up_jitsi_server
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

if [[ $reset -eq 1 ]]; then
  reset_jitsi_server
fi

if [[ $createuser -eq 1 ]]; then
  create_new_user $username $password
fi
