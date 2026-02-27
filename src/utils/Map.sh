rows=3
cols=3

declare -a matrix

set_tile() {
  local i=$1
  local j=$2
  local value=$3
  matrix[$((i * cols + j))]=$value
}

get_tile() {
  local i=$1
  local j=$2
  echo "${matrix[$((i * cols + j))]:- }"
}
