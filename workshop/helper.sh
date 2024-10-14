


case $@ in
  hugo-up|hup)
    hugo serve -D
    ;;
  test)
    echo "Executing test command"
    ;;
  *)
    echo "Command \"$@\" doesn't exist. Typo?"
    ;;
esac
