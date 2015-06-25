# Big history.  500 line default is way too small!
export HISTSIZE=10000
export HISTFILESIZE=10000

# no duplicate entries
export HISTCONTROL=ignoreboth:erasedups

# append history file
shopt -s histappend

# update histfile after every command
export PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

#export HISTIGNORE="ls:ps *:logout:reset*:history:git st:git br:tig:less *"


