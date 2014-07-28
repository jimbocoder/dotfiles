HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd $HERE >/dev/null

# Big history.  500 line default is way too small!
export HISTSIZE=10000
export HISTFILESIZE=10000

# Too much coffee this day, for real:
source .bash.d/ssh-completion.sh


popd >/dev/null
