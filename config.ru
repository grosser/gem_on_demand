# to run via rackup or passenger
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'gem_on_demand/server'
run GemOnDemand::Server
