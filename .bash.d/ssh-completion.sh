_complete_ssh_hosts ()
{
        COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"

        # Parse ~/.ssh/config for known hosts, avoiding wildcarded ones.
        local from_ssh_config=`grep '^Host .*'  ~/.ssh/config | tr -s ' ' | cut -d' ' -f2-  | tr ' ' '\n' | grep -v '[?*]' | tr '\n' ' '`

        # Find ssh commands from command history.  This is imperfect because plenty of "ssh" commands
        # don't necessarily start with "^ssh" but it's pretty good in practice..
        local from_history=`grep '^ssh ' ~/.bash_history | sort | uniq -d`
        COMPREPLY=( $(compgen -W "${from_ssh_config} ${from_history}" -- $cur))
        return 0
}
complete -F _complete_ssh_hosts ssh scp sftp
