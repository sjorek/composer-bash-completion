# Composer shell completion for Bash

The [`composer-completion.bash`](https://github.com/sjorek/composer-bash-completion/blob/master/composer-completion.bash)
script provides shell completion in bash for [composer](https://getcomposer.org).

The completion routines support completing all composer commands and options,
even if provided by plugins.

## Installation

1. Ensure you installed:
   * `bash` version >= 4.1
   * `bash-completion` version >= 2.0
   * `grep` in `$PATH`
   * `awk` in `$PATH`
   * `cut` in `$PATH`
   * `sed` in `$PATH`
   * `tr` in `$PATH`
   * ... and last but not least, `composer` version >= 1.5 of course!

2. Install this file:
   * a.) Either, place it in a `bash-completion.d` folder, like:
       * `/etc/bash-completion.d`
       * `/usr/local/etc/bash-completion.d`
       * `~/bash-completion.d`
   * b.) Or, copy it somewhere (e.g. `~/.composer-completion.sh`) and put the
     following line in your `.bashrc`:

     `source ~/.composer-completion.sh`
   * c.) If you're using [MacPorts](https://www.macports.org) then you should
     take a look at my [MacPorts-PHP](https://sjorek.github.io/MacPorts-PHP)
     repository.

## Want more?

There is a [composer-plugin](https://sjorek.github.io/composer-virtual-environment-plugin/)
complementing the bash-completion. And - once more - if you're using [MacPorts](http://macports.org), 
take a look at my [MacPorts-PHP](https://sjorek.github.io/MacPorts-PHP/)
repository.

Cheers!

