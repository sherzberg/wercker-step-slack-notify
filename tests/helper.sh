# if declare -f fatal; then
#   echo "skipping fatal definition: already defined"
# else
function fatal() {
  echo "fatal called with : $1"
  export FATAL_CALLED="true"
  if [ "$FATAL_MESSAGE" = "$1" ]; then
    echo "Exiting with 0"
    exit 0
  else
    echo "Fatal error: called with $1 expected $FATAL_MESSAGE"
    exit 1
  fi
}
# fi
