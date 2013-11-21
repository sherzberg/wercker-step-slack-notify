# if declare -f fatal; then
#   echo "skipping fatal definition: already defined"
# else
function fatal() {
  echo "fatal called with : $1"
  $FATAL_CALLED = 1
  if [ $FATAL_MESSAGE == $1 ]; then
    exit 0
  else
    exit 1
  fi
}
# fi
