require 'bundler/setup'
require 'bundler/gem_tasks'
require "rspec/core/rake_task"
require 'bump/tasks'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = false
  t.rspec_opts = '--backtrace --color'
end

task :default => :spec
