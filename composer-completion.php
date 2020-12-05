<?php
/*
 * composer-bash-completion
 * ========================
 *
 * Copyright (c) 2017-2020 [Stephan Jorek](mailto:stephan.jorek@gmail.com)
 *
 * Distributed under the 3-Clause BSD license
 * https://opensource.org/licenses/BSD-3-Clause
 *
 * Bash completion support for [composer](https://getcomposer.org)
 *
 * The contained completion routines provide support for completing
 * all composer commands and options, even those provided by plugins.
 *
 * Need help? [RTFM](https://sjorek.github.io/composer-bash-completion)!
 */

namespace Sjorek\Composer\BashCompletion;

exit(Generator::run());

/**
 * Composer Bash Completion Generator
 *
 * @author Stephan Jorek <stephan.jorek@gmail.com>
 */
class Generator
{

    const EXIT_CODE_MISSING_ARGUMENTS = 1;
    const EXIT_CODE_FAILED_TO_FETCH_JSON = 2;
    const EXIT_CODE_FAILED_TO_PARSE_JSON = 3;
    const EXIT_CODE_INVALID_JSON_FORMAT = 4;
    const EXIT_UNKNOWN_ERROR = 254;
    const EXIT_UNKNOWN_EXCEPTION = 255;

    /**
     * @throws \RuntimeException
     */
    public static function run()
    {
        try {
            if (!isset($_SERVER['argc']) || $_SERVER['argc'] < 6) {
                throw new \RuntimeException(
                    'Missing command-line arguments.',
                    self::EXIT_CODE_MISSING_ARGUMENTS
                );
            }

            $current = $_SERVER['argv'][1];
            $previous = $_SERVER['argv'][2];
            $isOption = 1 === (int) $_SERVER['argv'][3];
            $isAssigment = 1 === (int) $_SERVER['argv'][4];
            $compwords = array_filter(
                array_slice($_SERVER['argv'], 5),
                function($compword) {
                    return $compword !== '=';
                }
            );

            $generator = new Generator($current, $previous, $compwords, $isOption, $isAssigment);
            $exitCode = $generator->process();
        } catch (\Exception $e) {
            $exitCode = $e->getCode() ?: self::EXIT_UNKNOWN_EXCEPTION;
        } catch (\Throwable $t) {
            $exitCode = $t->getCode() ?: self::EXIT_UNKNOWN_ERROR;
        }
        return $exitCode;
    }

    /**
     * @var string
     */
    protected $composer;

    /**
     * @var string|null
     */
    protected $shellExec;

    /**
     * @var string|null
     */
    protected $command;

    /**
     * @var array
     */
    protected $commands;

    /**
     * @var array
     */
    protected $arguments;

    /**
     * @var array
     */
    protected $options;

    /**
     * @var array
     */
    protected $scripts;

    /**
     * @var array
     */
    protected $proxies;

    /**
     * @var array
     */
    protected $required;

    /**
     * @var array
     */
    protected $multiple;

    /**
     * @var array
     */
    protected $namespaces;

    /**
     * @var array
     */
    protected $definitions;

    /**
     * @var string
     */
    protected $current = '';

    /**
     * @var string
     */
    protected $previous = '';

    /**
     * @var array
     */
    protected $compwords = array();

    /**
    * @var bool
    */
    protected $isOption = false;

    /**
    * @var bool
    */
    protected $isAssigment = false;

    /**
     * @param string $current
     * @param string $previous
     * @param array  $compwords
     * @param bool   $isOption
     * @param bool   $isAssigment
     */
    public function __construct($current, $previous, array $compwords, $isOption, $isAssigment)
    {
        $this->current = $current;
        $this->previous = $previous;
        $this->composer = trim(array_shift($compwords));
        $this->compwords = $compwords;
        $this->isOption = $isOption;
        $this->isAssigment = $isAssigment;
    }

    public function process()
    {
        $this->shellExec = null;
        $this->command = null;
        $this->commands = array();
        $this->arguments = array();
        $this->options = array();
        $this->scripts = array();
        $this->proxies = array();
        $this->required = array();
        $this->multiple = array();
        $this->namespaces = array();
        $this->definitions = array();

        $this->load();

        $this->parseNamespaces();
        $this->parseDefinitions();
        if ($this->parseCompwords()) {
            $this->processCurrentDefinition();

            echo PHP_EOL;
            printf('composer=%s' . PHP_EOL, escapeshellarg($this->composer));
            printf('cmd=%s' . PHP_EOL, escapeshellarg($this->command));
            printf('args=%s' . PHP_EOL, escapeshellarg(implode(PHP_EOL, $this->arguments)));
            printf('opts=%s' . PHP_EOL, escapeshellarg(implode(PHP_EOL, $this->options)));
//             printf('commands=%s' . PHP_EOL, escapeshellarg(implode(' ', $this->commands)));
//             printf('scripts=%s' . PHP_EOL, escapeshellarg(implode(' ', $this->scripts)));
//             printf('proxies=%s' . PHP_EOL, escapeshellarg(implode(' ', $this->proxies)));
//             printf('required=%s' . PHP_EOL, escapeshellarg(implode(' ', $this->required)));
//             printf('multiple=%s' . PHP_EOL, escapeshellarg(implode(' ', $this->multiple)));
            echo PHP_EOL;
        }


        return 0;
    }

    public function exec($commandLine)
    {
        if ($this->shellExec === null) {
            $composer = explode(' ', $this->composer);
            $this->shellExec = implode(
                ' ',
                array_merge(
                    array(escapeshellcmd($composer[0])),
                    array_map('escapeshellarg', array_slice($composer, 1))
                )
            );
        }
        return shell_exec(sprintf($commandLine, $this->shellExec));
    }

    /**
     * @return void
     * @throws \RuntimeException
     */
    public function load()
    {
        // -n -vvv ... 2>/dev/null is a hack to support
        // https://github.com/sjorek/composer-silent-command-plugin
        $json = $this->exec('%s list -n -vvv --no-ansi --format=json 2>/dev/null');
        if (empty($json)) {
            throw new \RuntimeException(
                'Failed to fetch the composer help json.',
                self::EXIT_CODE_FAILED_TO_FETCH_JSON
            );
        }

        $json = json_decode($json, true, 20, JSON_OBJECT_AS_ARRAY);
        if (empty($json)) {
            throw new \RuntimeException(
                'Failed to parse the composer help json.',
                self::EXIT_CODE_FAILED_TO_PARSE_JSON
            );
        }

        if (!isset($json['namespaces'], $json['commands'])) {
            throw new \RuntimeException(
                'Invalid json format, either the namespaces- or the commands-definition is missing.',
                self::EXIT_CODE_INVALID_JSON_FORMAT
            );
        }

        // var_dump($json);

        $this->namespaces = $json['namespaces'];
        $this->definitions = $json['commands'];
    }

    /**
     * @return void
     */
    public function parseNamespaces()
    {
        $commands = array();
        foreach ($this->namespaces as $namespace) {
            $commands = array_merge($commands, $namespace['commands']);
        }
        $this->commands = $commands;
    }

    /**
     * @return void
     */
    public function parseDefinitions()
    {
        $scripts = array();
        $proxies = array();
        foreach ($this->definitions as $definition) {
            $commandName = $definition['name'];
            if ($definition['description'] === sprintf('Runs the %s script as defined in composer.json.', $commandName)) {
                $scripts[] = $commandName;
            } elseif(0 === strpos($definition['help'], 'The <info>run-script</info>')) {
                $scripts[] = $commandName;
            }
            foreach ($definition['definition']['arguments'] as $argument) {
                if ($argument['name'] === 'command-name') {
                    $proxies[] = $commandName;
                }
            }
        }
        $this->scripts = $scripts;
        $this->proxies = $proxies;
    }

    /**
     * @return boolean
     */
    public function parseCompwords()
    {
        $commands = $this->commands;
        $proxies = $this->proxies;
        foreach ($this->compwords as $compword) {
            if ($compword[0] == '-') {
                continue;
            }
            if (in_array($compword, $commands, true)) {
                if (in_array($compword, $proxies, true)) {
                    if (preg_match(sprintf('/ %s( |$)/', preg_quote($compword, '/')), $this->composer)) {
                        continue;
                    }
                    $this->composer  .= ' ' . $compword;
                    // Restart ...
                    $this->process();
                    return false;
                }
                $this->command = $compword;
                return true;
            }
        }
        return true;
    }

    /**
     * @return void
     */
    public function processCurrentDefinition()
    {
        $command = $this->command === null ? 'help' : $this->command;
        if ($this->current !== '' && $command === $this->current) {
            $this->arguments[] = $command . ' ';
            $this->command = '';
            return;
        }
        $isOption = $this->isOption || $this->isAssigment;
        foreach ($this->definitions as $definition) {
            $commandName = $definition['name'];
            if (!($command === $commandName || in_array($command, $definition['usage'], true))) {
                continue;
            }
            if (!$isOption) {
                foreach($definition['definition']['arguments'] as $argument) {
                    $argumentName = $argument['name'];
                    $this->parseArgument($commandName, $argumentName, $argument);
                }
                if (in_array('--', $this->compwords, true)) {
                    continue;
                }
            }
            if (
                ! (
                    $this->isAssigment ||
                    $this->command === null ||
                    in_array($commandName, $this->proxies, true) ||
                    empty($definition['definition']['arguments'])
                )
            ) {
                $this->options[] = '--';
            }
            foreach ($definition['definition']['options'] as $optionName => $option) {
                $this->parseOption($commandName, $optionName, $option);
            }
        }
    }

    /**
     * @param string $command
     * @param string $argument
     * @param array  $definition
     */
    public function parseArgument($command, $argument, array $definition)
    {
        switch ($argument) {
            case 'command_name':
                if ($command === 'help') {
                    $this->arguments = array_map(
                        function($command) {
                            return $command . ' ';
                        },
                        $this->commands
                    );
                }
                break;
            case 'script':
                if ($command === 'run-script') {
                    $this->arguments = array_map(
                        function($script) {
                            return $script . ' ';
                        },
                        $this->scripts
                    );
                }
                break;
            case 'binary':
                if ($command === 'exec') {
                    $this->arguments = array_map(
                        function($binary) {
                            return substr($binary, 2) . ' ';
                        },
                        array_filter(
                            explode(
                                PHP_EOL,
                                // -n -vvv ... 2>/dev/null is a hack to support
                                // https://github.com/sjorek/composer-silent-command-plugin
                                $this->exec(
                                    '%s exec -lq 2>/dev/null'
                                ) ?: ''
                            ),
                            function($line) {
                                return 0 < strlen(trim($line)) && 0 === strpos($line, '- ');
                            }
                        )
                    );
                }
                break;
        }
//         if ($definition['is_array']) {
//             $this->multiple[] = $command . '@' . $argument;
//         }
//         if ($definition['is_required']) {
//             $this->required[] = $command . '@' . $argument;
//         }
    }

    /**
     * @param string $command
     * @param string $option
     * @param array  $definition
     */
    public function parseOption($command, $option, array $definition)
    {
        $variants = array();
        foreach (array('name', 'shortcut') as $key) {
            if (empty($definition[$key])) {
                continue;
            }
            foreach (explode('|', $definition[$key]) as $variant) {
                $variants[] = $variant;
            }
        }
        if (empty($variants)) {
            return;
        }
        if (
            ! (
                $definition['is_multiple'] ||
                ($this->isOption && $this->current !== '' && in_array($this->current, $variants, true)) ||
                ($this->isAssigment && $this->previous !== '' && in_array($this->previous, $variants, true))
            )
        ) {
            $pattern = sprintf(
                '/(^| )(%s)(=| |$)/',
                implode(
                    '|',
                    array_map(
                        function ($variant) {
                            return preg_quote($variant, '/');
                        },
                        $variants
                    )
                )
            );
            $compwords = implode(' ', $this->compwords);
            if (preg_match($pattern, $compwords)) {
                return;
            }
        }
        foreach ($variants as $variant) {
            $this->parseOptionVariant($command, $option, $variant, $definition);
        }
    }

    /**
     * @param string $command
     * @param string $option
     * @param string $variant
     * @param array  $definition
     */
    public function parseOptionVariant($command, $option, $variant, array $definition)
    {
        $current = ($variant === $this->current || $variant === $this->previous);
        if ($this->isAssigment && !$current) {
            return;
        }
        $options=array();
        if ($definition['accept_value']) {
            if($this->isAssigment && $current) {
                switch ($command . '|' . $option) {
                    case 'archive|format':
                        $options[] = 'tar ';
                        $options[] = 'zip ';
                        break;
                    case 'licenses|format':
                    case 'outdated|format':
                    case 'show|format':
                        $options[] = 'text ';
                        $options[] = 'json ';
                        break;
                    case 'help|format':
                    case 'list|format':
                        $options[] = 'txt ';
                        $options[] = 'xml ';
                        $options[] = 'json ';
                        $options[] = 'md ';
                        break;
                    case 'create-project|stability':
                    case 'init|stability':
                        $options[] = 'stable ';
                        $options[] = 'RC ';
                        $options[] = 'beta ';
                        $options[] = 'alpha ';
                        $options[] = 'dev ';
                        break;
                    case 'init|type':
                    case 'search|type':
                        // $options[] = 'project ';
                        // $options[] = 'library ';
                        // $options[] = 'metapackage ';
                        // $options[] = 'composer-plugin ';
                        $options = explode(
                            PHP_EOL,
                            implode(
                                ' ' . PHP_EOL,
                                explode(
                                    ' ',
                                    // https://packagist.org/explore/?q=%2A&p=0
                                    // $('.search-facets-type .ais-menu--item a').each(function(e, i) { $('span', e).remove(); }).text();
                                    'aimeos-extension api application asgard-module behat-extension bitrix-module bundle cakephp-plugin claroline-plugin class component composer-installer composer-plugin concrete5-package contao-bundle contao-component contao-module craft-plugin dravencms-package drupal-drush drupal-module drupal-profile drupal-theme elefant-app elgg-plugin extension ezplatform-bundle ezpublish-legacy-extension flarum-extension framework fuel-package gplcart-module icanboogie-module joomla-package kohana-module laravel laravel-library laravel-package lib library lithium-library magento-module magento2-language magento2-module magento2-theme mediawiki-extension metapackage module mouf-library myadmin-plugin neos-package neos-plugin nette-addon newscoop-plugin october-plugin opis-colibri-module package phile-plugin php php-library phpbb-extension pimcore-plugin platform-extension plugin prestashop-module project propel-behavior rbschange-compatibility-module rbschange-module robo-tasks sallycms-addon sdk silverstripe-module silverstripe-theme silverstripe-vendormodule simplesamlphp-module standalone streams-addon sulu-bundle symfony-bundle symfony1-plugin tao-extension textpattern-plugin thelia-module tool typo3-cms-extension typo3-flow-package typo3-flow-plugin utility virtual-package windwalker-package wordpress-muplugin wordpress-plugin wordpress-theme wp-cli-package yii-extension yii2-extension yii2-module yii2-widget zf-module '
                                )
                            )
                        );
                        break;
                }
            } else {
                $options[] = $variant . '=';
            }
        } else {
            $options[] = $variant . ' ';
        }
        $this->options = array_merge($this->options, $options);
//         if ($definition['is_multiple']) {
//             $this->multiple[] = $command . '@' . $variant;
//         }
//         if ($definition['is_value_required']) {
//             $this->required[] = $command . '@' . $variant;
//         }
    }
}
