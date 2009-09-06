Link Checker
================================================
A reentrant link-checker for delicious power-users, stress-tested with stores of 12,000+ links.

Features:
 * Resilient to control-c interrupts, will resume checking where left off.
 * Delicious API responses cached locally so they need only be retrieved once.
 * Dead links persisted in a Moneta cache for you to deal with as you please, e.g.
 # % xatttr .moneta_cache/xattr_cache | xargs -n1 -I foo curl "http://api.delicious.com/delete?url=foo"

Todo:
 * cool animated progress indicator with ncurses
 * test sax parsing to see if it's a faster load
