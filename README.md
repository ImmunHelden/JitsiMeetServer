# Jitsi services deployment

This repository is based on https://github.com/jitsi/docker-jitsi-meet. It uses the `docker-compose` and `.env` file as ansible templates for deployment.

## Configuration

Most variables for configuring the jitsi docker containers can be adjusted from the ansible inventories.
Further configuration info can be found here https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker

Some variables are not implemented yet commented for example `JIGASI` or `LDAP` related configs.

## Usage

```bash
Usage examples:

  jitsi_ansible_wrapper --install
  jitsi_ansible_wrapper --start
  jitsi_ansible_wrapper --reset
  jitsi_ansible_wrapper --createuser --username <username> --password <password>

Options:
  -i,  --install                  # installs all jitsi related services and docker containers
  -r,  --remove                   # resets the host and removes everything jitsi related
  -u,  --up                       # starts all jitsi related services and docker containers
  -d,  --down                     # down all jitsi related services and docker containers
       --reset                    # runs all roles successively to completly reinstall and startup the jitsi services
  -cu, --creatuser                # create a new user
       --username <username>      # the username parameter for a new user
       --password <password>      # the password parameter for a new user
  -rs, --restart                  # starts all jitsi related services and docker containers
       --dry-run                  # Do not make any changes, just print ansible commands
  -v,  --version                  # Show program version
       --debug                    # Enable debug output
```

## Letsencrypt

Enable staging certificats

- Enable the mount for service web in docker-compose template `/pc/roles/configure_docker/create/templates/docker-compose.yml.j2`
  ```yaml
      # - ${CONFIG}/certbot-update.sh:/etc/cont-init.d/05-certboot-update
  ```
- Add parameter injection in ansible inventory `/inventory/inventory.ini` for variable `letsencrypt_email`
  ```ini
    letsencrypt_email="jitsi@meet.de --test-cert --break-my-certs"
  ```
