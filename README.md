# WordPress Auto Update

## Overview

### Look for updates

Generally WordPress regularly checks for updates with the [wordpress.org Version Check API][1].

By default, this is triggered when you visit the backend and by a [WP-Cron][2] task twice a day.

### Check prerequisites

Then, if a couple of checks (e.g. file system is writable) are passed the auto update will start.

**This plugin ensures that these checks also pass if [`DISALLOW_FILE_MODS`][3] is set to `true`.**

### Core/Plugins/Themes/Translations Update Behaviour

By default, since WordPress 5.6 the Auto Updater installs all WP Core updates and Translations.

Installations that initially got installed before WordPress 5.6 had Major versions disabled.
This setting is kept even when upgrading to WordPress >5.6.

**What this plugin does is "revert" the behaviour to what it was pre-5.6 -
only doing Minor WP Core Updates:**

|                | Minor (e.g.`6.1`->`6.1.1`) | Major (e.g.`6.1`->`6.2`) |
|----------------|----------------------------|--------------------------|
| WordPress Core | **Yes**                    | ~~**Yes**~~ **No**       |
| Plugins        | No                         | No                       |
| Themes         | No                         | No                       |
| Translations   | Yes                        | Yes                      |

---

**TL;DR:**

This plugin configures the Auto Updater to behave like this:

- Regular (2x/day) checks for updates
- Automatic Updates for core releases and translations
- No Automatic Update for Plugins and Themes

The rest of this document goes into the technical details on the behaviour of the Auto Updater. 

## Conditions for working updates

There are some conditions and prerequisites for auto updates to work:

### A writable filesystem

WordPress needs to be able to edit its own filesystem to be able to update itself.
This can either be done directly or as a fallback by accessing itself [via FTP][4].
The fallback is non-ideal and should be avoided.

### Not managed by a VCS

Also, WordPress will bail out early if it detects any VCS (Version Control System) like git.

### Updates need not be disabled

If one disabled the updates explicitly they are disabled.

### WP-Cron needs to be working

Updates are done via WP-Cron for it to not slow down user requests.
So without working WP-Cron no auto updates.

Be aware that since the WP-Cron runs on an HTTP request
sites behind .htaccess protection will not get the cron triggered.

## Auto Update Flow Part 1

The flow of the first part of the auto updater is basically this:

1. Checking if there are any updates available
2. Maybe triggering an auto-update.

### Checking for updates

Quite early in the startup process of WordPress the file `/wp-includes/update.php` is loaded
[adding action hooks][5].

This does multiple things:

A hook on [`admin_init`][6] triggers a check if the last check is older than 12h or the installed 
version changed since. This is only triggered by accessing the backend as well as admin-ajax.php.

Another hook on `init` makes sure automatic cron based checks are scheduled every 12h.
This also happens on requests to the front end, like a normal user visiting the site.

(For details on how this rate can be lowered remotely for security releases see Addendum A.)

Both then trigger a call to [`wp_version_check()`][7] which does the actual checking.

This function bails out early if
 - WordPress is currently being installed
 - the last check is younger than 60 seconds
 - the request to the .org API fails
 - there are no "offers" in the API response
 
If all goes well the update data is stored as a transient and we (might) continue to actually performing an update...

### Maybe triggering an auto update.

If the check for updates is run via the Cron task it will [trigger the auto updater][8].

## Auto Update Flow Part 2

The auto update itself is then handled by the `WP_Automatic_Updater` class inside
`wp-admin/includes/class-wp-automatic-updater.php`.

Before it kicks off an update it does some thorough checks to make sure the update will work:

### Check if the automatic updater is disabled

First of all WordPress [checks if the installation has automatic updates enabled][9]. This checks if:

- File modifications are allowed
- WordPress is not currently being installed
- the updates aren't completely disabled

These checks are based on multiple constants and filters:

If file modifications are allowed is checked via the [`wp_is_file_mod_allowed()`][10] function 
checking [`DISALLOW_FILE_MODS`][11] and the [`file_mod_allowed`][12] filter. (Also see Addendum B)

If WordPress is being installed is checked via [`wp_installing()`][13].

If updates are specifically disabled is checked via the [`AUTOMATIC_UPDATER_DISABLED`][14] and the 
[`automatic_updater_disabled`][15] filter.

### Check if we're on the main site/network if in a multisite install

This is done with the `is_main_network()` and `is_main_site()` functions.

### Check for fresh updates once more

Before we kick off the actual update a final check for fresh updates via `wp_version_check()` 
(which we already know from earlier on) is done.

### Find/Pick an update to do

Since the API always offers multiple options for upgrades we need to pick one that is allowed and 
matches best.

This is done by [`find_core_auto_update()`][16]. 
This function first filters out all updates that aren't of type `autoupdate`.

Next the code checks if we can and should do an update. This includes:
 
 - Checking the file system to be writeable
 - Checking if that specific version change is configured to be allowed - more on that later.
 - Checking if the PHP and MySQL version are supported
 
 Those checks, specifically the check for the specific version can be affected by multiple constants
 and filters. More on that later in the configurability section.
 
### Update!
 
If all this goes well the actual update is initiated.
How that works and what further checks might happen in the course of that process is another thing 
worthy of a separate document. Hence, we'll leave it with that for now.

## Update configuration

By default, from WordPress 5.6 on updates are configured to update WordPress Core and Translations.

But there are a plethora of options to change that:
 
 - [Automatic Core Updates, an update][17]
 - [The definitive guide to disabling auto updates in WordPress 3.7][18]
 - [Core major versions auto-updates UI changes in WordPress 5.6 – Correction][19]
 - [Configuring Automatic Background Updates][20]

## Addendum

### Addendum A - the Version Check API

Only slightly relevant to the actual working of the auto updater I briefly want to mention the 
["Version Check API"][1] on wordpress.org that supplies all WordPress installations with the data 
about possible updates.

At the time of writing this document there is no proper documentation. All that is known is the URL,
being http://api.wordpress.org/core/version-check/1.7/ and whatever can be inferred from the code, 
mostly from [`wp_version_check()`][7].

There are [plans to publish documentation in the future][21] which should show up somewhere here:
https://developer.wordpress.org/apis/

One interesting thing is that before security releases the API can 
[instruct WordPress to lower the check interval][22].

Currently, this seems to be done in such a way that at least 12 hours before a security release the 
check interval can be lowered from 12 hours to 60 minutes.

This information was retrieved from the [release handbook][23] and [somewhat confirmed in Slack][24].

Although this feature exists it is unclear if it is ever used.

### Addendum B - Enabling `DISALLOW_FILE_MODS` and still using auto updates

By default enabling `DISALLOW_FILE_MODS` does disable auto updates. But one can re-enable file 
modifications specifically for auto updates.

This can be done using the `file_mod_allowed` filter, limiting it to the `automatic_updater` context,
which this plugin does.

## Solum Plugin Boilerplate

This WordPress plugin is built using [Solum][25], a WordPress plugin boilerplate created by Thomas Kräftner for his
freelance work.

Since it is a boilerplate all that is needed for the ongoing development of this plugin is included in this repository.

Some basic information can be found in `SOLUM.md`. This notice is mostly only included to clear up any confusion should
the term "Solum" stand out in the source code.


[1]: https://codex.wordpress.org/WordPress.org_API#Version_Check 
[2]: https://developer.wordpress.org/plugins/cron/
[3]: https://developer.wordpress.org/apis/wp-config-php/#disable-plugin-and-theme-update-and-installation
[4]: https://wordpress.org/support/article/editing-wp-config-php/#wordpress-upgrade-constants
[5]: https://github.com/WordPress/WordPress/blob/f3b087164dcb42eb18bd7fa1e66e6ea116ccb0c2/wp-includes/update.php#L1084-L1103
[6]: https://developer.wordpress.org/reference/hooks/admin_init/
[7]: https://developer.wordpress.org/reference/functions/wp_version_check/
[8]: https://github.com/WordPress/WordPress/blob/f3b087164dcb42eb18bd7fa1e66e6ea116ccb0c2/wp-includes/update.php#L283-L291
[9]: https://github.com/WordPress/WordPress/blob/f3b087164dcb42eb18bd7fa1e66e6ea116ccb0c2/wp-admin/includes/class-wp-automatic-updater.php#L26-L57
[10]: ttps://developer.wordpress.org/reference/functions/wp_is_file_mod_allowed/
[11]: https://wordpress.org/support/article/editing-wp-config-php/#disable-plugin-and-theme-update-and-installation
[12]: https://developer.wordpress.org/reference/hooks/file_mod_allowed/
[13]: https://developer.wordpress.org/reference/functions/wp_installing/
[14]: https://wordpress.org/support/article/editing-wp-config-php/#disable-wordpress-auto-updates
[15]: https://developer.wordpress.org/reference/hooks/automatic_updater_disabled/
[16]: https://developer.wordpress.org/reference/functions/find_core_auto_update/
[17]: https://make.wordpress.org/core/2013/09/24/automatic-core-updates/
[18]: https://make.wordpress.org/core/2013/10/25/the-definitive-guide-to-disabling-auto-updates-in-wordpress-3-7/
[19]: https://make.wordpress.org/core/2020/11/24/core-major-versions-auto-updates-ui-changes-in-wordpress-5-6-correction/
[20]: https://wordpress.org/support/article/configuring-automatic-background-updates/
[21]: https://meta.trac.wordpress.org/ticket/4376
[22]: https://core.trac.wordpress.org/ticket/27772
[23]: https://make.wordpress.org/core/handbook/about/release-cycle/releasing-minor-versions/#security
[24]: https://wordpress.slack.com/archives/C02QB8GMM/p1565771746231600
[25]: https://github.com/hortulus/solum