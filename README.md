# DevKinsta Tools

Collection of small tools that provide additional features when developing websites using [DevKinsta](https://kinsta.com/de/devkinsta/).

----

## Installation

```shell
cd ~/DevKinsta/private
git clone https://github.com/stracker-phil/devkinsta-tools.git .
```

----

## Scripts

Here is a short overview of the scripts and what they can do for you:

### Need `--help`?

Use the param `-h` or `--help` on any script to display usage details and notes.  
For example `wp-cron.sh --help` or `site.sh -h`

### Script: `setup-backups.sh`

#### Usage

```shell
setup-backups.sh
setup-backups.sh --help
```

#### Description

> Important: Before running this script, please create at least one local website in DevKinsta!

Setup script to start automatic DB backups. You only need to run this script once (or after updating DevKinsta).

#### Setup Tasks

1. Install the `cron` daemon in devkinsta_fpm container
1. Register the `cron` service to the containers autostart scripts
1. Extract the MySQL credentials from the an existing DevKinsta website
1. Create a backup script that uses `mysqldump` to export each database to your `private/backups` folder
1. Register a cron task that calls the backup script every 3 hours.

### Script: `setup-xdebug.sh`

#### Usage

```shell
setup-xdebug.sh
setup-xdebug.sh --help
```

#### Description

Setup script to install and configure Xdebug for all available PHP modules. You only need to run this script once (or after updating DevKinsta).

#### Setup Tasks

1. Installs the xdebug module for all available php services
1. Creates xdebug.ini configuration
1. Enables Xdebug
1. Restarts all php services

### Script: `wp-cron.sh`

#### Usage

```shell
wp-cron.sh <website-dir> <interval>
wp-cron.sh --help

# Examples:
wp-cron.sh example-site 10  # Configure wp-cron with a 10 minute interval
wp-cron.sh example-site 0   # Disable wp-cron for example-site
wp-cron.sh example-site now # Run wp-cron once without chaning the interval
```

#### Params

* `<website-dir>` .. the folder name of the website inside the `~/DevKinsta/public` folder.
* `<interval>` .. accepts the following values:
    * `0` .. disable wp-cron
    * An integer value .. interval in minutes (e.g. `5`)
    * `now` .. run wp-cron once without modifying an existing cron interval

#### Description

Configures a cron service that calls wp-cron for the specified website in a custom interval.

Notes: The wp-cron event is triggerd via WP CLI. If this script is called before `setup-backups.sh` it will first install and configure the `cron` daemon for you.

### Script: `xdebug.sh`

#### Usage

```shell
xdebug.sh <state>
xdebug.sh --help

# Examples:
xdebug.sh on  # Enables Xdebug in all php services
xdebug.sh off # Completely disables Xdebug again
```

#### Params

* `<state>` .. Either "on" or "off"

#### Description

Enables or disables the xdebug php module. This script can only be used after calling `setup-xdebug.sh`!

Tip: Only enable Xdebug when you actually need it. While the module is active, your local website-performance decreases considerably!

### Script: `site.sh`

#### Usage

```shell
site.sh <action> <website-dir>
site.sh --help

# Examples:
site.sh disable example-site
site.sh enable example-site
```

#### Params

* `<state>` .. Either "enable" or "disable"
* `<website-dir>` .. the folder name of the website inside the `~/DevKinsta/public` folder.

#### Description

I noticed that DevKinsta gets slightly slower the more files are present inside the `public` folder. This script will help to keep the `public` folder lean and mean: When you "disable" a website, this script will move all files from the "public" folder to a new "archive" folder. At the same time, a small placeholder file is created inside your public-folder to remind you what happened to the website.

You can restore an archived website by calling the script with the action "enable" to undo that change.

### Script: `server.sh`

#### Usage

```shell
server.sh <web-server> <db-server>
server.sh --help

# Examples:
server.sh kinsta mamp # Use Nginx of DevKinsta but link it to the MAMP Pro MySQL server
server.sh mamp mamp   # MAMP Pro for webserver and MySQL
server.sh             # Use DevKinsta for web server and MySQL
```

#### Params

* `<web-server>` .. Either "kinsta" or "mamp". Default is "kinsta".
* `<db-server>` .. Either "kinsta" or "mamp". Default is "kinsta".

#### Description

> This is a very specific script and will only work on a **macOS** machine that has **[MAMP Pro v6](https://www.mamp.info/de/downloads/)** installed. It also requires a certain MAMP Pro configuration, which is documented inside the shell script.

When you set up MAMP Pro correctly, this script can be used to quickly switch between webservers and DB servers. Both, MAMP and DevKinsta, use the same codebase (i.e. the `DevKinsta/public/my-website` folder) but process that codebase using a differnt server.

**Some use cases:**

* For performance comparison of DevKinsta vs MAMP and to confirm migration of websites.
* MAMP uses Apache and DevKinsta nginx, this way you can have both
* Toggle between two DB states
* Quickly test a website on a mobile device using MAMP Viewer

**What it does:**

**Web server: `kinsta`**
1. Quit the MAMP Pro app (which stops all MAMP servers)
1. Restarts the two docker containers `devkista_fpm` and `devkinsta_nginx`
1. Restarts all php services in the `devkinsta_fpm` container

**Web server: `mamp`**
1. Stops the two docker containers `devkista_fpm` and `devkinsta_nginx`
1. Starts the MAMP Pro app (which starts relevant MAMP servers)

**DB Server: `kinsta`**
1. Updates all `wp-config.php` files and sets `DB_HOST` to either
    * `devkinsta_db` (when webserver is also `kinsta`)
    * `127.0.0.1:15100` (when webserver is `mamp`)

**DB Server: `mamp`**
1. Starts the MAMP Pro app (which starts relevant MAMP servers)
1. Updates all `wp-config.php` files and sets `DB_HOST` to either
    * `localhost:8889` (when webserver is also `mamp`)
    * `host.docker.internal:8889` (when webserver is `kinsta`)

----

## PhpStorm

Some tips and notes on integrating those scripts with PhpStorm

#### Configure Xdebug

When using PhpStorm, check out this guide on how to set up Xdebug for your project: 
> https://community.devkinsta.com/t/guide-how-to-set-up-xdebug-on-devkinsta-with-phpstorm/944/

#### Add scripts to your toolbar

In PhpStorm you can add the shell scripts above to your toolbar to quickly run commands like "Enable Xdebug" or "Run wp-cron":

1. Open **Settings | Tools | External Tools**, add a new tool:
    * Program: `{script}`, e.g. `xdebug.sh`
    * Arguments: `{params}`, e.g. `on`
    * Working dir: `/Users/{name}/DevKinsta/private`
    * Activate "Open console for tool output" (not required but recommended)
1. Open **Settings | Appearance & Behavior | Menus and Toolbars** and add your custom tools to a menu
    * I prefer the "Navigation Bar Toolbar" toolbar for this
    * Here you can assign a custom icon to the tools; I've included some icons in the `private/asset` folder

**Step 1:** Add a new external script
<img src="/asset/guide/phpstorm-tools-1.png?raw=true" />

**Step 2:** Add the tool to a toolbar/menu
<img src="/asset/guide/phpstorm-tools-2.png?raw=true" />
