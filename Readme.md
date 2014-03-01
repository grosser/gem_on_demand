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
Specify source with `http://localhost:7154/{user} in your Gemfile,<br/>
{user} is most likely your organization.

```Ruby
# source "https://rubygems.org" # need normal gems too ?
source "http://localhost:7154/grosser" # gem i gem_on_demand && gem-on-demand --server

gem "parallel"
gem "bump"
```

Always add and commit **`vendor/cache`** directory so gems can be installed on servers
```Bash
mkdir -p vendor/cache
bundle
```

TIPS
====
 - first bundle might fail because it takes to long, just keep trying until everything is cached
 - cache is in `~/.gem-on-demand/cache/{user}/{project}` in case you need to clean out some mistakes
 - only the most recent 50 versions are fetched for efficiency
 - heavily forked projects (rails/mysql/mysql) are not fetched for efficiency
 - cache is updated every 15 minutes to look for new tags, be patient or use `--expire`
 - port is `g=7` + `o=15` + `d=4` = 7154

OPTIONS
=======

```
    -s, --server                     Start server
    -e, --expire                     Expire gem cache for {user}/{project}
    -p, --port PORT                  Port for server (default 7154)
    -h, --help                       Show this.
    -v, --version                    Show Version
```

Boxen + passenger
=================

Run it in the background!

```Puppet
# modules/projects/manifests/gem_on_demand.pp
class projects::gem_on_demand {
  require team::dependency::config

  $dir = "${somewhere}/gem_on_demand"
  $ruby = $team::dependency::config::ruby_version

  boxen::project { 'gem_on_demand':
    ruby    => $ruby,
    source  => 'git@github.com:grosser/gem_on_demand.git',
    dir     => $dir,
    nginx   => "projects/gem_on_demand.conf.erb",
  }
}
```

```Nginx
# modules/projects/templates/gem_on_demand.conf.erb
server {
  listen 7154;
  root <%= @dir %>/public;
  passenger_ruby <%= scope.lookupvar "ruby::params::rbenv_root" %>/versions/<%= @ruby %>/bin/ruby;
  passenger_enabled on;
}
```

TODO
====
 - check how rubygems handles pre-release (x.y.z.PRE)
 - convert to thor + subcommand

Author
======

[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/grosser/gem_on_demand.png)](https://travis-ci.org/grosser/gem_on_demand)
