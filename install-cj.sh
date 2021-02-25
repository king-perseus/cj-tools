#!/bin/bash

echo
echo "Installing cj-tools"
echo "--------------------"

echo "1 - Checking for dependencies"
if ! which jq >/dev/null
then
  echo "Required component 'jq' is not installed.  Please install jq before installing Container Jockey"
  echo "https://stedolan.github.io/jq/"
  exit 1
elif ! which docker-compose >/dev/null
then
  echo "Required component 'docker-compose' is not found.  Please install docker-compose  before installing Container Jockey"
  exit 1
elif ! which docker >/dev/null
then
  echo "Required component 'docker' is not found.  Please install docker  before installing Container Jockey"
  exit 1
fi


echo "2 - Installing configuration and examples into /etc/cj-tools"
if ! mkdir -p /etc/cj-tools
then
  echo "Unable to create /etc/cj-tools.  Please run with sudo to give meeded rights."
  exit 1
fi
if [ -e /etc/cj-tools/cj.config ]
then
  echo "INFO: Skipping.  Configuration already exists"
else
  if ! cp cj.config /etc/cj-tools
  then
    echo "ERROR: Error installing cj.config"
    exit 1
  fi
  if ! cp -R examples /etc/cj-tools
  then
    echo "ERROR: Error installing examples"
    exit 1
  fi
  set -e # Fail on error
  # chown root:wheel -R /etc/cj-tools  # Mac OS does not support group root and Linux does not always have wheel.
  chmod -R 755 /etc/cj-tools
  set +e
fi

echo "3 - Installing cj-* scripts into /usr/bin"
cp cj-browse cj-monitor cj-compose /usr/local/bin
if [ $? -ne 0 ]
then
  echo "ERROR: Error copying scripts into /usr/bin"
  exit 1
else
  set -e # Fail on error
  # chown root:wheel /usr/local/bin/cj-browse /usr/local/bin/cj-monitor /usr/local/bin/cj-compose   # Mac OS does not support group root and Linux does not always have wheel.
  chmod 755 /usr/local/bin/cj-browse /usr/local/bin/cj-monitor /usr/local/bin/cj-compose
  set +e
fi

echo "4 - Deploying service definition"
if [[ "$OSTYPE" =~ linux ]]
then
  if [ -e /etc/systemd/system/cj-tools.hosts.service ]
  then
    echo "INFO: Service already exists in /etc/systemd/system/.  Stopping and redeploying."
    systemctl stop cj-tools.hosts.service
  fi
  if ! cp examples/cj-tools.hosts.service /etc/systemd/system/
  then
    echo "ERROR: Error copying .service file into /etc/systemd/system/"
    exit 1
  fi
  systemctl daemon-reload
  systemctl start cj-tools.hosts.service
elif [[ "$OSTYPE" == "darwin"* ]]  # "darwin20.0"*
then
  set -e # Fail on error
  launchctl load -w /etc/cj-tools/examples/org.cj-tools.hosts.plist
  launchctl start org.cj-tools.hosts
  # To delete, use launchctl unload -w /etc/cj-tools/examples/org.cj-tools.hosts.plist
  set +e
else
  echo "ERROR: I am unsure how to deply a service for OSTYPE=$OSTYPE.  Please file a bug report to request support."
  exit 1
fi
echo
echo "Install complete"
