# cj-tools

## What is this?

Container Jockey is a suite of tools to make it easy to work with sets of docker containers.  It provides the following components:

- **cj-monitor** - Keeps your /etc/hosts file up to date as containers are added/removed.  Includes comments on URLs for containers in the hosts file.
- **cj-browse** - Runs a container with midnight commander that lets you browse through docker volumes for running and stopped containers.
- **cj-compose** - Extends docker-compose to add missing features.

## Dependencies

- jq
- docker-compose
- Linux or Mac OS

## Getting Started

Download the project and run sudo ./install-cj.sh

The installer will:
1. Load configurations in /etc/cj-tools
2. Install the cj-* programs in /usr/bin
3. Register the cj-monitor service which updates the hosts file.

Once installed, you can immediately use cj-monitor and cj-browse without any other work (assuming docker is running).

## cj-monitor

cj-monitor keeps your hosts file up to date as containers are started/stopped.

The host entry for a container is composed of an IP address and FQDN like this:

`ipaddress hostname[.subdomain].basedomain`

Where:
- ***ipaddress***  - Primary address the service is listening on.
- ***hostname***   - Represents the short name of the container (machine).  For example "webserver"
- ***subdomain***  - Represents a grouping of hosts like docker compose project.  Example "mydemo"
- ***basedomain*** - Represents the domain the service runs in.  Can be anything but normally "mylaptop.localdomain" or just "local"

Note: References to "domainname" mean the combination of subdomain and basedomain.

cj-monitor determines how to update the hosts file by using the /etc/cj-tools/cj.config configuration file along with [container labels](https://docs.docker.com/config/labels-custom-metadata/).  

cj-monitor determines IP address, DNS name, etc using the following logic.  Note that "(default)" indicates how cj-monitor works on containers that no special configuration has been made.

***ipaddress***
1. Container label com.cj-tools.hosts.ip
2. (default) The IP address of the first network adapter registered to the container.

***hostname***
The host name is required and normally automatically determined.  Normally the docker-compose service name or the container name.  Defaults in this order...
3. Container label com.cj-tools.hosts.host_name if specified.
4. (default) Container label com.docker.compose.service which specifies the name of the docker-compose service the container was defined as.  e.g. "webserver"
5. (default) What the container thinks its hostname is as long as it is not exactly 12 characters long. If docker creates a cryptic host name it will look something like "8adc0dba4d95".
6. Name of the docker container.  Will not make sense if you didn't specify a name at create time.  e.g. "spanky_colden"

***Subdomain+Basedomain***
Setting com.cj-tools.hosts.use_container_domain overrides the combination of sub and base domain.

***Subdomain***
The subdomain is optional and normally only set for containers created through docker-compose.
1. Container label com.cj-tools.hosts.sub_domain.  This is used to override docker-compose project.
2. (default) The name of the Docker-compose stack or project.  Comes from label "com.docker.compose.project"
3. (default) Blank.
 
***Basedomain***
The base domain is required and normally automatically determined.  Defaults in this order...
1. Container label com.cj-tools.hosts.domain_name
2. If container label com.cj-tools.hosts.use_container_domain = true then basedomain comes from the container's domain property.  domain property must not be blank.
3. Configuration base_domain_name from /etc/cj-tools/cj.config
4. (default) Output of $(hostname -f)

## Summary of container labels:
-  com.docker.compose.service - Docker-compose service name for the container.  Set by specifying -p on docker-compose command line or setting environment variable COMPOSE_PROJECT_NAME.
-  com.cj-tools.hosts.ip - Overrides the logic to determine the container's IP address.
-  com.cj-tools.hosts.exclude - If true, excludes the container from the hosts file.
-  com.cj-tools.hosts.ip - IP address.  Overrides the logic to determine the container's IP address.
-  com.cj-tools.hosts.host_name - Host name.  Overrides logic to determine the container's host name.
-  com.cj-tools.hosts.base_domain_name - If not blank, provides the base domain used for the container's fqdn.  Subdomain is not overridden.
-  com.cj-tools.hosts.use_container_base_domain - If true, use container's Config.Domain as base domain.  Subdomain is not overridden.
-  com.cj-tools.hosts.use_container_domain - If true, .Config.Domain specifies the complete domain.  Subdomain settings are ignored.
You can control the URL output to hosts file via:
-  com.cj-tools.hosts.url - Uses this instead of the derived URL.
-  com.cj-tools.hosts.web_protocol - Defaults to "http"
-  com.cj-tools.hosts.web_port - Defaults to 80
