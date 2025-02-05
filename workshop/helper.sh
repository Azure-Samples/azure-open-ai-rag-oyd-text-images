#! /bin/bash

case $@ in
  hugo-up|hup)
    hugo serve -D
    ;;
  git-submodule-init|gsi)
    git submodule init 
    git submodule update
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


