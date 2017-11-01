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

#COMPOSER_COMPLETION_GENERATOR=
if [ -z "${COMPOSER_COMPLETION_GENERATOR}" ] && [ -r "${BASH_SOURCE%.bash}.php" ] ; then

    COMPOSER_COMPLETION_GENERATOR="$(realpath ${BASH_SOURCE%.bash}.php)"

elif [ -z "${COMPOSER_COMPLETION_GENERATOR}" ] ; then

    echo '"composer-bash-completion" not loaded' >&2
    echo 'A valid completion generator is missing.' >&2
    echo 'Please set COMPOSER_COMPLETION_GENERATOR accordingly.' >&2
    echo 'To reload the "composer-bash-completion", type: ' >&2
    echo '' >&2
    echo '    composer-completion-reload' >&2

    composer-completion-reload()
    {
        if [ -n "${COMPOSER_COMPLETION_GENERATOR}" ] ; then
            echo '"composer-bash-completion" generator-file configuration detected!'
            if [ -f "$BASH_SOURCE" ] && source "$BASH_SOURCE" ; then
                unset -f composer-completion-reload
                echo '"composer-bash-completion" has been reloaded.'
                return 0
            else
                echo 'Could not reload "composer-bash-completion".' >&2
                echo 'In this case source the "composer-completion.bash" again.' >&2
                return 1
            fi
        else
            echo 'A valid completion generator is missing.' >&2
            echo 'Please set COMPOSER_COMPLETION_GENERATOR accordingly.' >&2
            return 1
        fi
    }

elif type -t _get_comp_words_by_ref >/dev/null ; then

    _composer_completion_settings()
    {
        local composer
        composer="${1}"
        # -n -vvv ... 2>/dev/null is a hack to support
        # https://github.com/sjorek/composer-silent-command-plugin
        (
            ${composer} -n -vvv --no-ansi config -l ||
            ${composer} -n -vvv --no-ansi config -l --global
        ) 2>/dev/null |
            grep -o -E '^\[[^]]+\]' |
            tr -d '[]' |
            sort |
            uniq |
            sed -e 's|$| |g' |
            tr -s ' '
    }

    _composer_completion_show()
    {
        local composer package
        composer="${1}"
        package="${2:-}"
        # use direct ?
        # ${composer} -n -vvv --no-ansi --format=text --direct -N show ${package} 2>/dev/null

        # -n -vvv ... 2>/dev/null is a hack to support
        # https://github.com/sjorek/composer-silent-command-plugin
        ${composer} -n -vvv --no-ansi --format=text -N show "${package}" 2>/dev/null |
            sed -e 's|$| |g' |
            tr -s ' '
    }

    _composer_completion_search()
    {
        local composer package
        composer="${1}"
        package="${2}"
        # -n -vvv ... 2>/dev/null is a hack to support
        # https://github.com/sjorek/composer-silent-command-plugin
        ${composer} -n -vvv --no-ansi -nN search "${package}" 2>/dev/null |
            sed -e 's|$| |g' |
            tr -s ' '
    }

    _composer_completion()
    {
        local cur prev words

        COMPREPLY=()

        _get_comp_words_by_ref -n : cur prev words cword

        local is_option is_assignment

        if [[ ${cur} == -* ]] ; then
            is_option=1
        else
            is_option=0
        fi

        if [ "${cur}" = "=" ] && [[ ${prev} == -* ]] ; then
            cur=
            is_assignment=1
        elif [ "${prev}" = "=" ] && [[ ${words[cword-2]} == -* ]] ; then
            prev=${words[cword-2]}
            is_assignment=1
        else
            is_assignment=0
        fi

        # early return for known or predicted options
        if [ $is_assignment = 1 ] ; then
            case "${prev}" in
                -d|--*dir)
                    _filedir -d 2>/dev/null || COMPREPLY=($(compgen -d -- "${cur}"))
                    __ltrim_colon_completions "${cur}"
                    return 0
                    ;;
                --*file|--*link|--*symlink|--*path)
                    _filedir 2>/dev/null || COMPREPLY=($(compgen -f -- "${cur}"))
                    __ltrim_colon_completions "${cur}"
                    return 0
                    ;;
            esac
        fi

        local composer cmd args opts
        # local commands scripts proxies required multiple

        if ! source <(
            php ${COMPOSER_COMPLETION_GENERATOR} "${cur}" "${prev}" ${is_option} ${is_assignment} ${words[@]}
        ) ; then
            return 1
        fi

        # echo >&2
        # echo "prev : (${prev})" >&2
        # echo "cur  : (${cur})" >&2
        # echo "words: (${words[@]})" >&2
        # echo "cword: (${cword})" >&2
        # echo "is_o : (${is_option})" >&2
        # echo "is_a : (${is_assignment})" >&2
        # echo "comp : (${composer})" >&2
        # echo "cmd  : (${cmd})" >&2
        # echo "args : (${args})" >&2
        # echo "opts : (${opts})" >&2
        # echo >&2

        if [ "${args}" = '' ] ; then
            args='__empty__'
        fi

        if [ "${opts}" = '' ] ; then
            opts='__empty__'
        fi

        if [ -n "${cmd}" ]; then

            case "${cmd}" in
                config)
                    if [ $is_option = 0 ] && [ $is_assignment = 0 ] ; then
                        args=$(_composer_completion_settings "${composer}")
                    fi
                    ;;
                archive|depends|info|outdated|prohibits|remove|show|suggests|update|upgrade|why|why-not)
                    if [ $is_option = 0 ] && [ $is_assignment = 0 ] ; then
                        if [ "${cur}" = "" ] ; then
                            args=$(_composer_completion_show "${composer}")
                        elif [[ "${cur}" =~ ^[a-zA-Z0-9\/_-]*$ ]] ; then
                            args=$(_composer_completion_show "${composer}" "${cur}*")
                        fi
                    fi
                    ;;
                browse|install|require)
                    if [ $is_option = 0 ] && [ $is_assignment = 0 ] ; then
                        if [ "${cur}" = "" ] ; then
                            args=$(_composer_completion_show "${composer}")
                        elif [[ "${cur}" =~ ^[a-zA-Z0-9\/_-]{1,2}$ ]] ; then
                            args=$(_composer_completion_show "${composer}" "${cur}*")
                        elif [[ "${cur}" =~ ^[a-zA-Z0-9\/_-]{3,}$ ]] ; then
                            args=$(_composer_completion_search "${composer}" "${cur}")
                        fi
                    fi
                    ;;
            esac
        fi

        # Common part

        if [ "${args}" = '__empty__' ] ; then
            args=
        fi

        if [ "${opts}" = '__empty__' ] ; then
            opts=
        fi

        if [ "${args}" = '' ] && [ "${opts}" = '' ] ; then
            return 1
        fi

        local sep=$'\n' IFS=$'\t\n'
        COMPREPLY=($( compgen -W "${args}${sep}${opts}" -- "${cur}" ))
        __ltrim_colon_completions "${cur}"
        return 0
    }

    _composer_completion_detect_composer()
    {
        local composer
        for composer in $( compgen -ca | grep -E '^composer' ) ; do
            if compgen -A function -A builtin | grep -q -E "^${composer}$" ; then
                continue
            fi
            echo "${composer}"
        done
    }

    composer-completion-register()
    {
        local composer commands
        commands="${1:-}"
        if [ -z "${commands}" ] ; then
            commands=$(_composer_completion_detect_composer)
        fi
        for composer in ${commands} ; do
            if compgen -A function | grep -q -E "^${composer}$" ; then
                echo "Skipping registration of function '${composer}' for composer-bash-completion." >&2
                continue
            fi
            complete -o bashdefault -o nospace -F _composer_completion "${composer}"
        done
    }

    composer-completion-register "composer composer.phar $(_composer_completion_detect_composer)"

else

    echo 'composer-bash-completion not loaded' >&2
    echo 'It requires bash version >= 3.2 and bash-completion.' >&2
    echo 'For more information, type:' >&2
    echo '' >&2
    echo '    composer-completion-reload' >&2

    composer-completion-help()
    {
        if type -t _get_comp_words_by_ref >/dev/null ; then
            echo 'bash-completion detected!'
            if [ -f "$BASH_SOURCE" ] && source "$BASH_SOURCE" ; then
                unset -f composer-completion-help
                echo '"composer-bash-completion" has been reloaded.'
                return 0
            else
                echo 'Could not reload "composer-bash-completion".' >&2
                echo 'In this case source the "composer-completion.bash" again.' >&2
                return 1
            fi
        fi

        echo ''
        echo '"composer-bash-completion" requires bash version >= 3.2 and'
        echo 'depends on a number of utility functions from "bash-completion".'
        echo ''
        if [ "$(uname -s 2>/dev/null)" = 'Darwin' ] ; then
            if which port &>/dev/null ; then
                echo 'To install "bash-completion" with MacPorts, type:'
                echo ''
                echo '    sudo port install bash-completion'
                echo ''
                echo 'Be sure to add it to your bash startup, as instructed.'
                echo 'Detailed instructions on using MacPorts "bash":'
                echo ''
                echo '    https://trac.macports.org/wiki/howto/bash-completion'
                echo ''
            fi
            if which brew &>/dev/null; then
                echo 'To install "bash-completion" with Homebrew, type:'
                echo ''
                echo '    brew install bash-completion'
                echo ''
                echo 'Be sure to add it to your bash startup, as instructed.'
                echo ''
            fi
        fi
        if which apt-get &>/dev/null; then
            echo 'To install "bash-completion" with APT, type:'
            echo ''
            echo '    sudo apt-get install bash-completion'
            echo ''
        fi
        if which yum &>/dev/null; then
            echo 'To install "bash-completion" with yum, run as root:'
            echo ''
            echo '    yum install bash-completion'
            echo ''
        fi
        echo 'To install bash-completion manually, please see instructions at:'
        echo ''
        echo '    https://github.com/scop/bash-completion#installation'
        echo ''
        echo 'Once bash and bash-completion are installed and loaded,'
        echo 'you may reload composer-completion:'
        echo ''
        echo "    source $BASH_SOURCE"
        echo ''
    }

fi
