Run your own gem server that fetches from github, uses tags as version and builds gems on demand

 - no gem pushing / works with old versions of you private repos
 - no permission issues (you can only install what you have github access to)

Install
=======

```Bash
git clone git@github.com:grosser/gem_on_demand.git
cd gem_on_demand
ruby app.rb
```

Usage
=====
Specify a source with username in your gemfile

```Ruby
source "http://localhost:4567/grosser"

gem "parallel"
gem "bump"
```

ALWAYS have a vendor/cache directory and add it to git so gem can be installed on a remote server.
```Bash
mkdir -p vendor/cache
bundle
```

TODO
====
 - tests
 - travis
 - caching of versions and dependencies (atm just showing last 3 versions because it would take forever)

Author
======

[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/grosser/gem_on_demand.png)](https://travis-ci.org/grosser/gem_on_demand)
