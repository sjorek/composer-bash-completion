#!bash
#
# composer-bash-completion
# ========================
#
# Copyright (c) 2017 [Stephan Jorek](mailto:stephan.jorek@gmail.com)
#
# Distributed under the 3-Clause BSD license
# https://opensource.org/licenses/BSD-3-Clause
#
# Bash completion support for [composer](https://getcomposer.org)
#
# The contained completion routines provide support for completing
# all composer commands and options, even those provided by plugins.
#
# Need help? [RTFM](https://sjorek.github.io/composer-bash-completion)!
#

_composer_search()
{
    # ( ${1} --no-ansi -nN search "${2}" | \
    #     grep -E "^[a-zA-Z0-9_-]+\/${2}[a-zA-Z0-9_-]*$" ) 2>/dev/null
    ${1} --no-ansi -nN search "${2}" 2>/dev/null
}

_composer_commands()
{
    ( ${1} --no-ansi list | \
        awk "/Available commands:/{f=1;next} f" | \
        cut -f 3 -d " " | \
        tr "\\n" " " | \
        tr -s " " ) 2>/dev/null
}

_composer_options()
{
    ( ${1} --no-ansi --format=txt help ${2} | \
        awk "/Options:/{f=1;next} /Help:/{f=0} f" | \
        grep -o -E "(\-\-[a-z0-9=-]+|-[a-z0-9\\|]+)" | \
        sed -e "s#|# -#g" | \
        tr "\\n" " " | \
        tr -s " " ) 2>/dev/null
}

_composer_settings()
{
    ( ${1} --no-ansi global config -l | \
        grep -E "^\\[" | \
        cut -f 2 -d "[" | \
        cut -f 1 -d "]" ) 2>/dev/null
    ( ${1} --no-ansi config -l | \
        grep -E "^\\[" | \
        cut -f 2 -d "[" | \
        cut -f 1 -d "]" ) 2>/dev/null
}

_composer_scripts()
{
    ( ${1} --no-ansi run-script -l | \
        tr "\\n" " " | \
        tr -s " ") 2>/dev/null
}

_composer()
{
    local cmd cur prev opts commands isOpts
    COMPREPLY=()
    cmd="${COMP_WORDS[0]}"
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    local base_commands=$(_composer_commands ${cmd})

    if [[ "${prev}" =~ ^[a-z0-9-]+$ ]] && [[ "${base_commands}" =~ (^| )${prev}( |$) ]]; then
        opts=$(_composer_options ${cmd} ${prev})
    else
        opts=$(_composer_options ${cmd})
    fi

    if [[ ${cur} == -* ]]; then
        isOpts=1
    else
        isOpts=0
    fi

    case "${prev}" in
    composer*|global|help)
        commands="${base_commands}"
        ;;

    config)
        if [ $isOpts == 0 ]; then
            commands=$(_composer_settings ${cmd})
        fi
        ;;

    run-script)
        if [ $isOpts == 0 ]; then
            commands=$(_composer_scripts ${cmd})
        fi
        ;;

    depends)
        if [ $isOpts == 0 ]; then
            commands=$(_composer_search ${cmd} ${cur})
        fi
        ;;

    archive|browse|depends|install|prohibits|remove|require|show|suggests|update|upgrade)
        if [ $isOpts == 0 ] && [[ "${cur}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            commands=$(_composer_search ${cmd} ${cur})
        fi
        ;;

    esac


    # Common part
    if [ $isOpts == 1 ]; then
        COMPREPLY=($( compgen -W "${opts}" -- "${cur}" ))
    else
        COMPREPLY=($( compgen -W "${commands}" -- "${cur}" ))
    fi
    return 0

}

complete -o default -F _composer composer composer.phar \
    $( compgen -ca | grep -E "^composer" | grep -v -E "^composer(\\.phar)?$" )
