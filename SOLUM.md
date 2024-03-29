# Solum

Solum is a WordPress plugin boilerplate.

It is part of the Hortulus family created by Thomas Kräftner for his freelance work.

## Features

- **Docker based development environment** - Develop and test your plugin with all the tools you need. 
  Do this without messing with your host system or worrying about differing setups when working in a team.
- **Management CLI** - The boilerplate comes with a simple Bash script to initialize, start and clean the 
  development environment.
- **Configure versions** - Change WordPress and PHP versions with ease.  
- **Batteries included** - Apart from WordPress the setup also includes various tools: [WP-CLI](wp-cli.org/),
  [phpMyAdmin](https://www.phpmyadmin.net/), [MailHog](https://github.com/mailhog/MailHog)

## Prerequisites

Currently, Solum has only been tested with Ubuntu 18.04, but should probably run on other Linux systems and maybe
even a Mac.

Since most things happen inside Docker wrapped by a thin layer of Bash scripting you'll only need:

- [Docker](https://docs.docker.com/v17.09/engine/installation/)
- [docker-compose](https://docs.docker.com/compose/install/)
- bash and common CLI tools like `find`, `grep`, `sed` and `nc` 

## Basic Usage

This is a short overview of the main commands to get started quickly.
For a full list of available commands run  `./cli help`

### 1. Initialize the Plugin and Development Environment

`./cli init`

This will prepare a new plugin in multiple steps:

1. Create an `.env` file and open it so you can edit it to your liking.
2. If starting a project from scratch it will offer to interactively create a `composer.json` with some sane defaults.
3. If starting a project from scratch it will offer to interactively create a `package.json` with some sane defaults.
4. It will give you instructions what to add to your `etc/hosts` file.

(Step 4 is intentionally a manual step since messing with `etc/hosts` would require `sudo` which we don't want Solum to 
ever have.)

### 2. Start the Development Environment

`./cli start`

This will launch the development environment after doing some basic checks.
(E.g. if you did run `./cli init` before and the `etc/hosts` is set up properly.)

### Stop the Development Environment

`./cli stop`

If you just want to stop the development environment without removing the containers run `./cli stop`.
This will just stop the Docker containers, but not remove anything.

### Clean up the Development Environment

`./cli clean`

If you want to destroy the development environment and start from scratch run `./cli clean`.
This will *not* remove the configuration created with `./cli init`, so you could run `./cli start` right after.

## Advanced Usage

These are some further things you can do with the setup out of the box.

### Code Style (PHP_CodeSniffer) 

The composer file generated by default includes the 
[`inpsyde/php-coding-standards`](https://github.com/inpsyde/php-coding-standards/) which add 
[PHP_CodeSniffer](https://github.com/squizlabs/PHP_CodeSniffer) standards that are more modern/sane than the official
WordPress standards.

It also adds two composer scripts to check or auto-fix the codebase:

`./cli composer lint:php`

`./cli composer fix:php`

### Export Plugin

The composer file generated by default includes a script to bundle the plugin, including the autoloader/vendor folder
as a * .zip file for using in a non-composer managed default install of WordPress:

`./cli composer plugin-zip`

While normally a global composer setup is preferred this is still needed often enough to warrant an inclusion of this
feature by default.

### Pre-Release Checks

You can run this to do pre-release checks:

`./cli composer pre-release`

By default, it only checks the Code Style but if there are further things to check add them here.

## FAQs

### Solum, what's with the name?

It's [latin for "soil"](https://la.wiktionary.org/wiki/solum). Which felt kind of fitting for a boilerplate and also
goes well with the naming of the Hortulus parent project.

### I would need feature X. Can you make it work?

This is first and foremost my personal setup for my work. So any feature additions will only be considered if they are
relevant for my use cases. But of course feel free to fork Solum and turn it into whatever you need.

### Are you interested in contributions?

If you're talking about new features - see above.

If you're talking about a bug - see below.

### Something broke. Can you help me?

If you've found a bug or found a way to do anything cleaner or more elegant I'm always interested.

But please keep in mind that this is first and foremost my personal setup for my work.
So unless you are a paying client I *might* have a look at the issue.
If the issue sounds like something relevant for me and comes with a detailed and ideally reproducible description
this will increase the chances.