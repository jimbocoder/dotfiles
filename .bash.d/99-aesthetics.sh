# No git output
export PS1="\[$(tput setaf 2)\]\u@\h\[$(tput setaf 5)\]\$(echo)\[$(tput setaf 3)\]:\$(shortpath)\[$(tput sgr0)\]\\$ "

# With git status stuff
# export PS1="\[$(tput setaf 2)\]\u@\h\[$(tput setaf 5)\]\$(__git_ps1)\[$(tput setaf 3)\]:\$(shortpath)\[$(tput sgr0)\]\\$ "

# yes colors pls
export CLICOLOR=1

# Adds trailing/  slashes/  to directories
alias ls='ls -p'

