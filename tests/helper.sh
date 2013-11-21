# if declare -f fatal; then
#   echo "skipping fatal definition: already defined"
# else
function fatal() {
  echo "fatal called with : $1"
  exit 0
}
# fi
