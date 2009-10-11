# Rubunkulous!

**A reentrant link-checker for delicious power-users, stress-tested with 50x the average user's no. of links.**

To install:

        sudo gem install gemcutter && gem tumble && sudo gem install rubunkulous

### Features

 * Dead links are persisted in a [Moneta cache](http://github.com/wycats/moneta/tree/master) for you to deal with as you please, e.g.

        xattr .moneta_cache/xattr_cache | xargs -n1 -I foo curl "http://api.delicious.com/delete?url=foo"

 * Fully stateful / self-healing; the last-checked link and any failed links are cached in the Moneta store for lossless reentrance.
 * [Delicious API](http://delicious.com/help/api) responses cached locally so they need only be retrieved once.

### Usage

 1. enter your delicious username and password into credentials.yml
 2. ./rubunkulous.rb

Rubunkulous is designed to perform well despite network errors, curl timeouts, etc. If it dies due to an uncaught exception (it shouldn't), just restart it and it will pick up where it left off.

### Todo

 * cool animated progress indicator - DONE!
 * use [/posts/recent](http://delicious.com/help/api#posts_recent) and [/posts/update](http://delicious.com/help/api#posts_update) to do smarter change-detection to avoid re-fetches as new links are added. ([/posts/all?hashes](http://delicious.com/help/api#posts_all_hashes) also exists but doesn't look useful in this situation, since we only want new appends to the head of the stack)
 * test [SAX parsing](http://www.tutorialspoint.com/ruby/ruby_xml_xslt.htm) to see if it's a faster load
 * explore pipelining more link fetches in parallel (will require synchronized lock on link cursor)
