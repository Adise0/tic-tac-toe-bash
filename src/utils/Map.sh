rows=3
cols=3

declare -a matrix

set_tile() {
  local i=$2
  local j=$1
  local value=$3
  matrix[$((i * cols + j))]=$value
}

get_tile() {
  local i=$2
  local j=$1
  echo "${matrix[$((i * cols + j))]:- }"
}
