<?php
/**
 * This is a defense-in-depth fallback to prevent directory listing
 * - if this folder ends up in production (which the deployment process should prevent)
 * - the .htaccess didn't block access to the folder
 */