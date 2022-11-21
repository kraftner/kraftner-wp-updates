<?php
/**
 * Plugin Name: Kraftner WordPress Updates
 * Description: Configures WordPress Auto Updates to work even with <code>DISALLOW_FILE_MODS</code> set to <code>true</code>. Also disables Auto Core Updates for Major versions.
 * Version: 0.1.0
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

/**
 * Disable Auto Core Updates for Major versions.
 * This is needed since in WP >= 5.6 it would otherwise be enabled.
 *
 * @link https://make.wordpress.org/core/2020/11/24/core-major-versions-auto-updates-ui-changes-in-wordpress-5-6-correction/
 */
add_filter( 'allow_major_auto_core_updates', '__return_false' );

