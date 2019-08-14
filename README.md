# WordPress Auto Update

## Overview

Generally WordPress does regular checks with the [wordpress.org Version Check API][1].
By default this is triggered when you visit the backend and by a [Cron][2] task twice a day.

By default the Auto Updater only updates to minor releases (`5.1`->`5.1.1`) but nothing else (**not** `5.1`->`5.2`).

TODO: Confirm this -> 
It also does update translations.

What it doesn't update by default are Plugins and Themes.

There are several options to configure and dis- and enable parts of the auto update functionality.
This is done with constants and/or filters described later on.

This document focuses on the default state of updates being minor core updates.
It might hint at other things the core updater can do, but doesn't go into detail about it. 

**TL;DR:**
- Regular (2x/day) checks for updates
- Automatic Updates for minor core releases and translations
- No Automatic Update for Plugins and Themes
- Various options to configure all of this 

## Conditions for working updates

There are some conditions and prerequisites for auto updates to work:

- A writable filesystem

Obviously WordPress needs to be able to edit its own filesystem to be able to update itself.
This can either be done directly or as a fallback by accessing itself [via FTP][3]. The fallback is non-ideal and 
should be avoided.

- Not managed by a VCS

Also WordPress will bail out early if it detects any VCS (Version Control System) like git.

- Updates need not to be disabled

Obviously if one disabled the updates explicitly they are disabled.

- Cron needs to be working

Updates are done via Cron so it doesn't slow down user requests. So without working Cron no aut updates.

## Auto Update Flow Part 1

The flow of the first part of the auto updater is basically this:

1. Checking if there are any updates available
2. Triggering an auto-update.

### Checking for updates

Quite early in the startup process of WordPress the file `/wp-includes/update.php` is loaded [adding action hooks][4].

This does multiple things:

A hook on [`admin_init`][5] triggers a check if the last check is older than 12h or the installed version changed since.
This is only triggered by accessing the backend as well as admin-ajax.php.

Another hook on `init` makes sure automatic cron based checks are scheduled every 12h.
This also happens on requests to the front end, like a normal user visiting the site.

(For details on how this rate can be lowered remotely for security releases see Addendum A.)

Both then trigger a call to [`wp_version_check()`][6] which does the actual checking.

This function bails out early if
 - WordPress is currently being installed
 - the last check is younger than 60 seconds
 - the request to the .org API fails
 - there are no "offers" in the API response
 
If all goes well the update data is stored as a transient and we (might) continue to actually performing an update...

### Maybe triggering an auto update.

If the check for updates is run via the Cron task it will [trigger the auto updater][7].

## Auto Update Flow Part 2

The auto update itself is then handled by the `WP_Automatic_Updater` class inside
`wp-admin/includes/class-wp-automatic-updater.php`.

Before it kicks off an update it does some thorough checks to make sure the update will work:

### Check if the automatic updater is disabled

First of all WordPress [checks if the installation has automatic updates enabled][8]. This checks if:

- File modifications are allowed
- WordPress is not currently being installed
- the updates aren't completely disabled

These checks are based on multiple constants and filters:

If file modifications are allowed is checked via the [`wp_is_file_mod_allowed()`][9] function checking 
[`DISALLOW_FILE_MODS`][10] and the [`file_mod_allowed`][11] filter.

If WordPress is being installed is checked via [`wp_installing()`][12].

If updates are specifically disabled is checked via the [`AUTOMATIC_UPDATER_DISABLED`][13] and the 
[`automatic_updater_disabled`][14] filter.

### Check if we're on the main site/network if in a multisite install

This is done with the `is_main_network()` and `is_main_site()` functions.

### Check for fresh updates once more

Before we kick off the actual update a final check for fresh updates via `wp_version_check()` (which we already know
from earlier on) is done.

### Find/Pick an update to do

Since the API always offers multiple options for upgrades we need to pick one that is allowed and matches best.

This is done by [`find_core_auto_update()`][15]. 
This function first filters out all updates that aren't of type `autoupdate`.

Next it checks if we can and should do an update. This includes:
 
 - Checking the file system to be writeable
 - Checking if that specific version change is configured to be allowed - more on that later.
 - Checking if the PHP and MySQL version are supported
 
 Those checks, specifically the check for the specific version can be affected by multiple constants and filters.
 More on that later in the configurability section.
 
### Update!
 
If all this goes well the actual update is initiated.
How that works and what further checks might happen in the course of that process is another thing worthy of a separate
document. Hence we'll leave it with that for now.

## Update configuration

By default updates are configured to only update the following

- dev versions
- patch releases (`5.1`->`5.1.1`) but nothing else (**not** `5.1`->`5.2`)

There are a plethora of options to change that though which were already wonderfully summarised in two posts at the time
of the release of the auto updater:
 
 - [Automatic Core Updates, an update][16]
 - [The definitive guide to disabling auto updates in WordPress 3.7][17] 

## Addendum

### Addendum A - the Version Check API

Only slightly relevant to the actual working of the auto updater I briefly want to mention the "Version Check API" on
wordpress.org that supplies all WordPress installations with the data about possible updates.

At the time of writing this document there is no proper documentation. All that is known is the URL, being
http://api.wordpress.org/core/version-check/1.7/ and whatever can be inferred from the code, mostly from 
[`wp_version_check()`][6].

There are [plans to publish documentation in the future][18] which should show up somewhere here:
https://developer.wordpress.org/apis/

One interesting thing is that before security releases the API can [instruct WordPress to lower the check interval][19].

Currently this seems to be done in such a way that at least 12 hours before a security release the check interval is
lowered from 12 hours to 1 hour.

This information was retrieved from the [release handbook][20] and [somewhat confirmed in Slack][21].

### Addendum B - Enabling `DISALLOW_FILE_MODS` and still using auto updates

By default enabling `DISALLOW_FILE_MODS` does disable auto updates. But one can re-enable file modifications
specifically for auto updates.

This can be done using the `file_mod_allowed` filter like such:

```
add_filter('file_mod_allowed',
    /**
     * Allow file modifications for the automatic updater, and only that, even if `DISALLOW_FILE_MODS`is `true`.
     *
     * @see WP_Automatic_Updater::is_disabled
     *
     * @param bool   $file_mod_allowed Whether file modifications are allowed.
     * @param string $context          The usage context.
     *
     * @return bool
     */
    function ($file_mod_allowed, $context) {

        if ($context === 'automatic_updater') {
            return true;
        }

        return $file_mod_allowed;
    },
10, 2);
```

[1]: https://codex.wordpress.org/WordPress.org_API#Version_Check 
[2]: https://developer.wordpress.org/plugins/cron/
[3]: https://wordpress.org/support/article/editing-wp-config-php/#wordpress-upgrade-constants
[4]: https://github.com/WordPress/WordPress/blob/428a738f1d0a9f6bde7900e9b54d12afbfb8bbcf/wp-includes/update.php#L816-L835
[5]: https://developer.wordpress.org/reference/hooks/admin_init/
[6]: https://github.com/WordPress/WordPress/blob/428a738f1d0a9f6bde7900e9b54d12afbfb8bbcf/wp-includes/update.php#L9-L244
[7]: https://github.com/WordPress/WordPress/blob/428a738f1d0a9f6bde7900e9b54d12afbfb8bbcf/wp-includes/update.php#L235-L243
[8]: https://github.com/WordPress/WordPress/blob/428a738f1d0a9f6bde7900e9b54d12afbfb8bbcf/wp-admin/includes/class-wp-automatic-updater.php#L25-L56
[9]: https://developer.wordpress.org/reference/functions/wp_is_file_mod_allowed/
[10]: https://wordpress.org/support/article/editing-wp-config-php/#disable-plugin-and-theme-update-and-installation
[11]: https://developer.wordpress.org/reference/hooks/file_mod_allowed/
[12]: https://developer.wordpress.org/reference/functions/wp_installing/
[13]: https://wordpress.org/support/article/editing-wp-config-php/#disable-wordpress-auto-updates
[14]: https://developer.wordpress.org/reference/hooks/automatic_updater_disabled/
[15]: https://developer.wordpress.org/reference/functions/find_core_auto_update/
[16]: https://make.wordpress.org/core/2013/09/24/automatic-core-updates/
[17]: https://make.wordpress.org/core/2013/10/25/the-definitive-guide-to-disabling-auto-updates-in-wordpress-3-7/
[18]: https://meta.trac.wordpress.org/ticket/4376
[19]: https://core.trac.wordpress.org/ticket/27772
[20]: https://make.wordpress.org/core/handbook/about/release-cycle/releasing-minor-versions/#security
[21]: https://wordpress.slack.com/archives/C02QB8GMM/p1565771746231600