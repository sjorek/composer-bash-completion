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

if type complete &>/dev/null && type compgen &>/dev/null; then

    _composer_commands()
    {
        if declare -p _COMPOSER_LOCAL_COMMANDS >/dev/null 2>&1 && \
           declare -p _COMPOSER_GLOBAL_COMMANDS >/dev/null 2>&1
        then
            if [[ "${1}" =~ global ]] ; then
                echo "${_COMPOSER_GLOBAL_COMMANDS}"
            else
                echo "${_COMPOSER_LOCAL_COMMANDS}"
            fi
        else
            ( ${1} --no-ansi --format=txt list | \
                awk "/Available commands:/{f=1;next} f" | \
                cut -f 3 -d " " | \
                tr "\\n" " " | \
                tr -s " " ) 2>/dev/null
            ( ${1} --no-ansi --format=txt list | \
                awk "/Available commands:/{f=1;next} f" | \
                grep -E "\\[.*\\]" | \
                cut -f 2 -d "[" | \
                cut -f1 -d "]" |  \
                tr "|" "\\n" | \
                tr "\\n" " " | \
                tr -s " " ) 2>/dev/null
        fi
    }

    _composer_options()
    {
        local cmd

        if [ "${2}" = "" ] ; then
            cmd="_global"
        else
            cmd=$( echo -n "${2}" | tr ":" "_" )
        fi

        if [[ "${1}" =~ global ]] && declare -p _COMPOSER_GLOBAL_OPTIONS >/dev/null 2>&1 && \
           [[ "${!_COMPOSER_GLOBAL_OPTIONS[@]}" =~ (^| )$cmd( |$) ]]
        then
            echo "${_COMPOSER_GLOBAL_OPTIONS[$cmd]}"
        elif [[ ! "${1}" =~ global ]] && declare -p _COMPOSER_LOCAL_OPTIONS >/dev/null 2>&1 && \
             [[ "${!_COMPOSER_LOCAL_OPTIONS[@]}" =~ (^| )$cmd( |$) ]]
        then
            echo "${_COMPOSER_LOCAL_OPTIONS[$cmd]}"
        else
            ( ${1} --no-ansi --format=txt help ${2} | \
                awk "/Options:/{f=1;next} /Help:/{f=0} f" | \
                grep -o -E " (\-\-[a-z0-9=-]+|-[a-z0-9\\|]+)" | \
                sed -e "s#|# -#g" | \
                tr "\\n" " " | \
                tr -s " " ) 2>/dev/null
        fi
    }

    _composer_settings()
    {
        if declare -p _COMPOSER_LOCAL_SETTINGS >/dev/null 2>&1 && \
           declare -p _COMPOSER_GLOBAL_SETTINGS >/dev/null 2>&1
        then
            if [[ "${1}" =~ global ]] ; then
                echo "${_COMPOSER_GLOBAL_SETTINGS}"
            else
                echo "${_COMPOSER_LOCAL_SETTINGS}"
            fi
        else
            ( ${1} --no-ansi global config -l | \
                grep -E "^\\[" | \
                cut -f 2 -d "[" | \
                cut -f 1 -d "]" ) 2>/dev/null
            ( ${1} --no-ansi config -l | \
                grep -E "^\\[" | \
                cut -f 2 -d "[" | \
                cut -f 1 -d "]" ) 2>/dev/null
        fi
    }

    _composer_scripts()
    {
        if declare -p _COMPOSER_LOCAL_SCRIPTS >/dev/null 2>&1 && \
           declare -p _COMPOSER_GLOBAL_SCRIPTS >/dev/null 2>&1
        then
            if [[ "${1}" =~ global ]] ; then
                echo "${_COMPOSER_GLOBAL_SCRIPTS}"
            else
                echo "${_COMPOSER_LOCAL_SCRIPTS}"
            fi
        else
            ( ${1} --no-ansi run-script -l | \
                tr "\\n" " " | \
                tr -s " ") 2>/dev/null
        fi
    }

    _composer_show()
    {
        # ( ${1} --no-ansi --format=text --direct -N show "${2}" ) 2>/dev/null
        ( ${1} --no-ansi --format=text -N show ${2} ) 2>/dev/null
    }

    _composer_search()
    {
        # ( ${1} --no-ansi -nN search "${2}" | \
        #     grep -E "^[a-zA-Z0-9_-]+\/${2}[a-zA-Z0-9_-]*$" ) 2>/dev/null
        ${1} --no-ansi -nN search ${2} 2>/dev/null
    }

    _composer_cache_completion()
    {
        local cmd key
        if [ "${1}" = "" ] ; then
            echo "Missing name of composer executable as first argument"
        else
            _composer_uncache_completion

            echo -n "- cache composer's local command completion: "
            _COMPOSER_LOCAL_COMMANDS=$(_composer_commands ${1})
            echo "done."

            echo -n "- cache composer's local options completion: "
            declare -g -A _COMPOSER_LOCAL_OPTIONS
            _COMPOSER_LOCAL_OPTIONS[_global]=$(_composer_options ${1})
            for cmd in ${_COMPOSER_LOCAL_COMMANDS} ; do
                echo -n "."
                key=$( echo -n "${cmd}" | tr ":" "_" )
                _COMPOSER_LOCAL_OPTIONS[$key]=$(_composer_options ${1} "${cmd}")
            done
            echo " done."

            echo -n "- cache composer's local settings completion: "
            _COMPOSER_LOCAL_SETTINGS=$(_composer_settings ${1})
            echo "done."

            echo -n "- cache composer's local scripts completion: "
            _COMPOSER_LOCAL_SCRIPTS=$(_composer_scripts ${1})
            echo "done."

            echo -n "- cache composer's global command completion: "
            _COMPOSER_GLOBAL_COMMANDS=$(_composer_commands "${1} global")
            echo "done."

            echo -n "- cache composer's global options completion: "
            declare -g -A _COMPOSER_GLOBAL_OPTIONS
            _COMPOSER_GLOBAL_OPTIONS[_global]=$(_composer_options "${1} global")
            for cmd in ${_COMPOSER_GLOBAL_COMMANDS} ; do
                echo -n "."
                key=$( echo -n "${cmd}" | tr ":" "_" )
                _COMPOSER_GLOBAL_OPTIONS[$key]=$(_composer_options "${1} global" "${cmd}")
            done
            echo " done."

            echo -n "- cache composer's global settings completion: "
            _COMPOSER_GLOBAL_SETTINGS=$(_composer_settings "${1} global")
            echo "done."

            echo -n "- cache composer's global scripts completion: "
            _COMPOSER_GLOBAL_SCRIPTS=$(_composer_scripts "${1} global")
            echo "done."
        fi
    }

    _composer_uncache_completion()
    {
        echo -n "- purge cached composer completion: "
        unset _COMPOSER_LOCAL_COMMANDS
        unset _COMPOSER_LOCAL_OPTIONS
        unset _COMPOSER_LOCAL_SETTINGS
        unset _COMPOSER_LOCAL_SCRIPTS
        unset _COMPOSER_GLOBAL_COMMANDS
        unset _COMPOSER_GLOBAL_OPTIONS
        unset _COMPOSER_GLOBAL_SETTINGS
        unset _COMPOSER_GLOBAL_SCRIPTS
        echo "done."
    }

    _composer()
    {
        local composer current options commands index
        local commandCandidate commandList currentCommand currentIsOption

        COMPREPLY=()
        composer="${COMP_WORDS[0]}"
        if type _get_comp_words_by_ref &>/dev/null; then
          _get_comp_words_by_ref -n = -n @ -n : -c current
        else
          current="${COMP_WORDS[COMP_CWORD]}"
        fi

        commandList=$(_composer_commands "${composer}")
        currentCommand=""
        for index in "${!COMP_WORDS[@]}" ; do
            commandCandidate="${COMP_WORDS[$index]}"
            if [ "${COMP_WORDS[$index + 1]}" = ":" ] ; then
                commandCandidate="${commandCandidate}:"
            elif [ "${commandCandidate}" = ":" ] ; then
                commandCandidate="${COMP_WORDS[$index - 1]}:${COMP_WORDS[$index + 1]}"
            fi
            if [ "${commandCandidate}" = "${composer}" ] || [ "${commandCandidate}" = "${composer} global" ] ; then
                continue
            fi
            if [[ "${commandCandidate}" =~ ^[a-z0-9:-]+$ ]] && [[ "${commandList}" =~ (^| )${commandCandidate}( |$) ]]; then
                if [ "${commandCandidate}" = "global" ] ; then
                    composer="${composer} global"
                    commandList=$(_composer_commands "${composer}")
                    continue
                else
                    currentCommand="${commandCandidate}"
                fi
                break
            fi
        done

        commands="${commandList}"
        options=$(_composer_options "${composer}" "${currentCommand}")
        if [[ ${current} == -* ]]; then
            currentIsOption=1
        else
            currentIsOption=0
        fi

        case "${currentCommand}" in
            config)
                if [ $currentIsOption == 0 ]; then
                    commands=$(_composer_settings "${composer}")
                fi
                ;;

            run-script)
                if [ $currentIsOption == 0 ]; then
                    commands=$(_composer_scripts "${composer}")
                fi
                ;;

            archive|depends|info|outdated|prohibits|remove|show|suggests|update|upgrade|why|why-not)
                if [ $currentIsOption == 0 ] ; then
                    if [ "${current}" = "" ] ; then
                        commands=$(_composer_show "${composer}" "${current}")
                    elif [[ "${current}" =~ ^[a-zA-Z0-9\/_-]*$ ]] ; then
                        commands=$(_composer_show "${composer}" "${current}*")
                    fi
                fi
                ;;

            browse|install|require)
                if [ $currentIsOption == 0 ] ; then
                    if [ "${current}" = "" ] ; then
                        commands=$(_composer_show "${composer}" "${current}")
                    elif [[ "${current}" =~ ^[a-zA-Z0-9\/_-]{1,2}$ ]] ; then
                        commands=$(_composer_show "${composer}" "${current}*")
                    elif [[ "${current}" =~ ^[a-zA-Z0-9\/_-]{3,}$ ]] ; then
                        commands=$(_composer_search "${composer}" "${current}")
                    fi
                fi
                ;;

        esac

        # Common part
        if [ $currentIsOption == 1 ] ; then
            COMPREPLY=($( compgen -W "${options}" -- "${current}" ))
        elif [ -z "${currentCommand}" ] ; then
            COMPREPLY=($( compgen -W "${commands} ${options}" -- "${current}" ))
        else
            COMPREPLY=($( compgen -W "${options}" -- "${current}" ))
        fi

        __ltrim_colon_completions "$current"

        return 0
    }

    complete -o default -F _composer composer composer.phar \
        $( compgen -ca | grep -E "^composer" | grep -v -E "^composer(\\.phar)?$" )

fi
