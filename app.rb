require 'bundler/setup'
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'gem_on_demand/server'

GemOnDemand::Server.run!
