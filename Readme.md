Run your own gem server that fetches from github, uses tags as version and builds gems on demand

 - no gem pushing / works with old versions of you private repos
 - no permission issues (you can only install what you have github access to)

Install
=======

```Bash
gem install gem_on_demand
gem-on-demand --server
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

TIPS
====
 - first bundle might fail because it just takes to long, just keep trying until everything is cached
 - cache is in `~/.gem_on_demand/cache/{user}/{project}` in case you need to clean out some mistakes
 - only the most recent 50 versions are fetched to be efficient
 - cache is updated every 15 minutes to look for new tags, so be patient
 - port is `g=7` + `o=15` + `d=4` = 7154

OPTIONS
=======

```
    -s, --server                     Start server
    -p, --port PORT                  Port for server (default 7154)
    -h, --help                       Show this.
    -v, --version                    Show Version
```

TODO
====
 - `expire user/project` command to clear updated_at + not_found
 - Ctrl+c stops subcommand but not the entire request
 - check how rubygems handles pre-release (x.y.z.PRE)
 - convert to thor + subcommand

Author
======

[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/grosser/gem_on_demand.png)](https://travis-ci.org/grosser/gem_on_demand)
