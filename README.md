# [Composer shell completion for Bash](https://sjorek.github.io/composer-bash-completion/)

The [`composer-completion.bash`](composer-completion.bash)
script provides shell completion in bash for [composer](https://getcomposer.org).

The completion routines support completing all composer commands and options,
even if provided by plugins.


## Installation

If you're using [MacPorts](https://www.macports.org) then you should
take a look at my [MacPorts-PHP](https://sjorek.github.io/MacPorts-PHP)
repository. In all other cases:

1. Ensure you installed:
   * `bash` (version 4.x or above)
   * `bash-completion` (version 2.x or above)
   * additionally you need to have the following tools in `PATH`:
       * `php` (version 5.5 or above)
       * `grep`
       * `sed`
       * `tr`
       * `sort`
       * `uniq`
   * … and last but not least, `composer` (version 1.5 or above) of course!

2. Install `composer-completion.php` file:
   * copy it somewhere (e.g. `~/.composer-completion.php`) and put the
     following line in your `~/.bash_profile`:

         `export COMPOSER_COMPLETION_PHP_SCRIPT=~/.composer-completion.php`

   * you can also nail down the php interpreter to use by adding the
     following line in your `~/.bash_profile`:

         `export COMPOSER_COMPLETION_PHP=/path/to/your/php`

3. Install `composer-completion.bash` file:
   * a.) Either, place it in a `bash-completion.d` folder, like:
       * `/etc/bash-completion.d`
       * `/usr/local/etc/bash-completion.d`
       * `~/.bash-completion.d`
   * b.) Or, copy it somewhere (e.g. `~/.composer-completion.bash`) and put the
     following line in your `~/.bash_completion`:

         `source ~/.composer-completion.bash`


## Contributing

Look at the [contribution guidelines](CONTRIBUTING.md)


## Want more?

There is a [composer-plugin](https://sjorek.github.io/composer-virtual-environment-plugin/)
complementing the bash-completion. And - once again - if you're using [MacPorts](http://macports.org),
take a look at my [MacPorts-PHP](https://sjorek.github.io/MacPorts-PHP/)
repository.

Cheers!
