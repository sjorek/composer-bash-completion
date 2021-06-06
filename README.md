# [Composer shell completion for Bash](https://sjorek.github.io/composer-bash-completion/)

The [`composer-completion.bash`](composer-completion.bash)
script provides shell completion in bash for [composer](https://getcomposer.org).

The completion routines support completing all composer commands and options,
even if provided by plugins.


## Installation

If you're using [Homebrew](https://brew.sh), you should tap my 
[Homebrew-PHP](https://sjorek.github.io/homebrew-php/) repository.
And if you're using [MacPorts](https://www.macports.org), you should
use my [MacPorts-PHP](https://sjorek.github.io/macports-php) repository.

Manual installation (not recommend on Mac OS, see above):

1. Ensure you installed:
   * `bash` version ≥ 4.x, including ≥ 5.x
   * `bash-completion` version ≥ 2.x
   * additionally you need to have the following tools in `PATH`:
       * `php` version ≥ 5.6, including ≥ 7.x and ≥ 8.x
       * `grep`
       * `sed`
       * `tr`
       * `sort`
       * `uniq`
   * … and last but not least, `composer` version ≥ 1.5, including ≥ 2.x

2. Install `composer-completion.php` file:
   * copy it somewhere (e.g. `~/.composer-completion.php`) and put the
     following line in your `~/.bash_profile`:

         export COMPOSER_COMPLETION_PHP_SCRIPT=~/.composer-completion.php

   * you can also nail down the php interpreter to use by adding the
     following line in your `~/.bash_profile`:

         export COMPOSER_COMPLETION_PHP=/path/to/your/php

3. Install `composer-completion.bash` file:
   * a.) Either, place it in a `bash-completion.d` folder, like:
       * `/etc/bash-completion.d`
       * `/usr/local/etc/bash-completion.d`
       * `~/.bash-completion.d`
   * b.) Or, copy it somewhere (e.g. `~/.composer-completion.bash`) and put the
     following line in your `~/.bash_completion`:

         source ~/.composer-completion.bash


## Contributing

Look at the [contribution guidelines](CONTRIBUTING.md)


## Want more?

If you're using [Homebrew](https://brew.sh), take a look at my 
[Homebrew-PHP](https://sjorek.github.io/homebrew-php/) tap.

If you're using [MacPorts](https://macports.org), take a look at my 
[MacPorts-PHP](https://sjorek.github.io/macports-php/) repository.

Cheers!
