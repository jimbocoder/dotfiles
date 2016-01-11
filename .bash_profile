if [[ -h "${BASH_SOURCE[0]}" ]];
then
    __FILE__="$HOME/$(readlink "${BASH_SOURCE[0]}")"
else
    __FILE__="$HOME/${BASH_SOURCE[0]}"
fi

__DIR__=$(dirname $__FILE__)

pushd $__DIR__ >/dev/null

source $(brew --prefix)/etc/bash_completion

for module in .bash.d/*.sh .bash.d/*.bash
do
    source "$module"
done


#source .bash.d/history.sh

# Too much coffee this day, for real:
source .bash.d/ssh-completion.sh


popd >/dev/null
