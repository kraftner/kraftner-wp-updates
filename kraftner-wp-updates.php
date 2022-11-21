<?php
/**
 * Plugin Name: Kraftner WordPress Updates
 * Description: Configures WordPress to enable auto updates with the kraftner-boilerplate-wordpress stack
 * Version: 0.0.2
 * Requires PHP: 7.3
 * Author: Thomas Kräftner <thomas@kraftner.com>
 * Author URI: https://kraftner.com/
 * Text Domain: kraftner-wp-updates
 * Domain Path: /languages
 * Update URI: false
 */

declare(strict_types=1);

add_filter('file_mod_allowed',

    /**
     * Allow file modifications for the automatic updater, and only that, even if `DISALLOW_FILE_MODS` is `true`.
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
