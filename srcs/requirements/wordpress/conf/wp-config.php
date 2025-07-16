<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the installation.
 * You don't have to use the website, you can copy this file to "wp-config.php"
 * and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * Database settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://developer.wordpress.org/advanced-administration/wordpress/wp-config/
 *
 * @package WordPress
 */

// ** Database settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', getenv('SQL_DATABASE'));

/** Database username */
define('DB_USER', getenv('SQL_USER'));

/** Database password */
define('DB_PASSWORD', getenv('SQL_PASSWORD'));

/** Database hostname */
define( 'DB_HOST', 'mariadb' );

/** Database charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8mb4' );

/** The database collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication unique keys and salts.
 *
 * Change these to different unique phrases! You can generate these using
 * the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}.
 *
 * You can change these at any point in time to invalidate all existing cookies.
 * This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',         'J!eO36sO7M@{NNa+@VWl3g{`iTtjO}n9kKBurd^8_Z)2k*DW;65gdNV@o38ZIVHV' );
define( 'SECURE_AUTH_KEY',  'h*b/fgVm;Fv0br_+R:A~?dPBW* II(g!?O1^`wyP)eadN}1p5]cMkZ#i8I-XTRF6' );
define( 'LOGGED_IN_KEY',    '4RepVY >UVCn<ABNb`QL T=ezg9zDI{~I]>@h6;@a<xGf ]3`KJyhihk3.CAUtDb' );
define( 'NONCE_KEY',        '.yU;7#c1FdDqF!Nm`{llVhn(PRLMxNd2KWQkRX:-W2 _,ZMvi%S@oe:<[Hh$.m/K' );
define( 'AUTH_SALT',        'Pu`0$l5qp8M]rgoFC7M==P^Qp<#k.[5Z83jxO$(~IjYv0O&Q=3N]U+w#|sM1]/.u' );
define( 'SECURE_AUTH_SALT', 'b1TYB$nw6UQnDrM%<0f:A<.e#DD0?x!6Q9+5~/V1GnUm8RlbA#ZGT`{:>w0w+OUR' );
define( 'LOGGED_IN_SALT',   'qHT+|{0G2F`wa~7d}KPH!RNmaJc@[>)!kAKKU95WHrU_GQr*q1{[a0mdkm.*Frfc' );
define( 'NONCE_SALT',       'h?t5+<bG]|v1AH&@y{XVrPmo%76K8`db!x*b.10,:z}liygXeGcXWwvakfT3wRp`' );

/**#@-*/

/**
 * WordPress database table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 *
 * At the installation time, database tables are created with the specified prefix.
 * Changing this value after WordPress is installed will make your site think
 * it has not been installed.
 *
 * @link https://developer.wordpress.org/advanced-administration/wordpress/wp-config/#table-prefix
 */
$table_prefix = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the documentation.
 *
 * @link https://developer.wordpress.org/advanced-administration/debug/debug-wordpress/
 */
define( 'WP_DEBUG', false );

/* Add any custom values between this line and the "stop editing" line. */



/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';