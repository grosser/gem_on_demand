require 'bundler/setup'
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = false
  t.rspec_opts = '--backtrace --color'
end

task :default => :spec
