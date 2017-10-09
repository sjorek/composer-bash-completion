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
    local composer current options commands
    local commandCandidate commandList currentCommand currentIsOption

    COMPREPLY=()
    composer="${COMP_WORDS[0]}"
    current="${COMP_WORDS[COMP_CWORD]}"

    commandList=$(_composer_commands ${composer})
    currentCommand=""

    for commandCandidate in "${COMP_WORDS[@]}" ; do
        if [ "${commandCandidate}" = "${composer}" ] ; then
            continue
        fi
        if [[ "${commandCandidate}" =~ ^[a-z0-9-]+$ ]] && [[ "${commandList}" =~ (^| )${commandCandidate}( |$) ]]; then
            currentCommand="${commandCandidate}"
            if [ "${currentCommand}" = "global" ] ; then
                continue
            fi
            break
        fi
    done

    options=$(_composer_options ${composer} ${currentCommand})

    if [[ ${current} == -* ]]; then
        currentIsOption=1
    else
        currentIsOption=0
    fi

    if [ "${currentCommand}" = "" ] ; then
        commands="${commandList}"
    else
        case "${currentCommand}" in
            global|help)
                commands="${commandList}"
                ;;

            config)
                if [ $currentIsOption == 0 ]; then
                    commands=$(_composer_settings ${composer})
                fi
                ;;

            run-script)
                if [ $currentIsOption == 0 ]; then
                    commands=$(_composer_scripts ${composer})
                fi
                ;;

            depends)
                if [ $currentIsOption == 0 ]; then
                    commands=$(_composer_search ${composer} ${current})
                fi
                ;;

            archive|browse|depends|install|prohibits|remove|require|show|suggests|update|upgrade)
                if [ $currentIsOption == 0 ] && [[ "${current}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                    commands=$(_composer_search ${composer} ${current})
                fi
                ;;

        esac
    fi


    # Common part
    if [ $currentIsOption == 1 ]; then
        COMPREPLY=($( compgen -W "${options}" -- "${current}" ))
    else
        COMPREPLY=($( compgen -W "${commands} ${options}" -- "${current}" ))
    fi
    return 0

}

complete -o default -F _composer composer composer.phar \
    $( compgen -ca | grep -E "^composer" | grep -v -E "^composer(\\.phar)?$" )
