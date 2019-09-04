
# The official direnv thing to do is simply:
# eval "$(direnv hook bash)"

# But the hook script provided thusly modifies PROMPT_COMMAND directly, and that fucks with
# iterm2 shell integration, because it uses this project to manage that variable indirectly:
# https://github.com/rcaloras/bash-preexec

# So, if we're using iterm2_shell_integration, we need to write our own, slightly tweaked script.

# For reference, here's the script normally provided by `direnv hook bash`
#
#
# _direnv_hook() {
#   local previous_exit_status=$?;
#   eval "$("/usr/local/bin/direnv" export bash)";
#   return $previous_exit_status;
# };
# if ! [[ "${PROMPT_COMMAND:-}" =~ _direnv_hook ]]; then
#   PROMPT_COMMAND="_direnv_hook${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
# fi


# And here's my tweaked version. It's more complicated than probably necessary.

# First, I want to extract the definition of the _direnv_hook function as
# defined above. This is in case they decide to change this function in a
# future release. This is probably getting silly, but it works.

_direnv_hook_function_definition=$(direnv hook bash | awk '/^_direnv_hook\(\) {/{flag=1}/^};$/{print;flag=0}flag')

# Now I have the definition, I can declare the function:

eval "$_direnv_hook_function_definition"

# FINALLY, instead of messing around with PROMPT_COMMAND like the packaged
# script, I can register this function as a pre-command function!

# if ! [[ "${PROMPT_COMMAND:-}" =~ _direnv_hook ]]; then
#   PROMPT_COMMAND="_direnv_hook${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
# fi
precmd_functions+=(_direnv_hook)
