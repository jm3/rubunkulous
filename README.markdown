# Link Checker

**A reentrant link-checker for delicious power-users, stress-tested with stores of 12,000+ links.

## Features

 * Dead links are persisted in a [Moneta cache](http://github.com/wycats/moneta/tree/master) for you to deal with as you please, e.g.

    xatttr .moneta_cache/xattr_cache | xargs -n1 -I foo curl "http://api.delicious.com/delete?url=foo"

 * Resilient to control-c interrupts, will resume checking where left off.
 * Delicious API responses cached locally so they need only be retrieved once.

## Todo

 * cool animated progress indicator with (n)curses
 * test [SAX parsing](http://www.tutorialspoint.com/ruby/ruby_xml_xslt.htm) to see if it's a faster load
