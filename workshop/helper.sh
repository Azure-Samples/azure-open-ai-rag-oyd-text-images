#! /bin/bash

case $@ in
  hugo-up|hup)
    hugo serve -D
    ;;
  dryrun-create-resource-group)
    echo "az group create --name ${resource_group_name} --location ${region}"
    ;;
  dryrun-docker-up)
    echo "$@"
    ;;
  test)
    echo "Executing test command"
    exe echo ls
    ;;
  *)
    echo "Command \"$@\" doesn't exist. Typo?"
    ;;
esac


