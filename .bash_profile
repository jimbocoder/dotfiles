#source .bashrc
source ~/.bashrc

if [[ `uname -s` == "Darwin" ]] ;
then
    __FILE__="$(realpath -P "${BASH_SOURCE[0]}")"
else
    __FILE__="$(readlink -f "${BASH_SOURCE[0]}")"
fi

__DIR__=$(dirname $__FILE__)
pushd $__DIR__ >/dev/null

# On Mac, enable homebrew completions
[[ `uname -s` == "Darwin" ]] && source $(brew --prefix)/etc/bash_completion


#for module in "$CONF_D"/*.sh "$CONF_D"/*.bash

CONF_D=bash.conf.d/
MODULES=$(find "$CONF_D" -type f -and \( -executable -or -name '*.sh' -or -name '*.bash' \) | sort -g)
for module in $MODULES; do
        source "$module"
done

popd >/dev/null


# vim: ft=sh

#_byobu_sourced=1 . /usr/bin/byobu-launch 2>/dev/null || true

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"
