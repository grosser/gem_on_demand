require "spec_helper"
require "gem_on_demand/version"

describe "GemOnDemand::CLI" do
  def gem_on_demand(command, options={})
    sh("#{Bundler.root}/bin/gem-on-demand #{command}", options)
  end

  def kill_all_children
    pid = Process.pid
    child_pids = all_children(pid)
    child_pids = child_pids + child_pids.map { |pid| all_children(pid) }
    Process.kill 9, *child_pids.flatten
  end

  def all_children(pid)
    pipe = IO.popen("ps -ef | grep #{pid}")
    pipe.readlines.map do |line|
      parts = line.split(/\s+/)
      parts[2] if parts[3] == pid.to_s and parts[2] != pipe.pid.to_s
    end.compact.map(&:to_i)
  end

  def sh(command, options={})
    result = `#{command} #{"2>&1" unless options[:keep_output]}`
    raise "#{options[:fail] ? "SUCCESS" : "FAIL"} #{command}\n#{result}" if $?.success? == !!options[:fail]
    result
  end

  it "shows version" do
    gem_on_demand("-v").strip.should == "#{GemOnDemand::VERSION}"
    gem_on_demand("--version").strip.should == "#{GemOnDemand::VERSION}"
  end

  it "shows help" do
    gem_on_demand("-h").should include "Run your own gem server"
    gem_on_demand("--help").should include "Run your own gem server"
  end

  it "fails with empty options" do
    gem_on_demand("", :fail => true).should include "Run your own gem server"
  end

  it "can boot a server" do
    Thread.new { gem_on_demand("--server") }
    sleep 3 # let server boot
    result = `curl --silent localhost:7154/grosser/api/v1/dependencies?gems=statsn`
    kill_all_children unless ENV["CI"]
    Marshal.load(result).should == [
      {:name=>"statsn", :number=>"0.1.0", :platform=>"ruby", :dependencies=>[["newrelic_rpm", "~> 3.5"]]},
      {:name=>"statsn", :number=>"0.1.1", :platform=>"ruby", :dependencies=>[["newrelic_rpm", "~> 3.5"]]}
    ]
  end

  it "can expire a cache" do
    GemOnDemand.dependencies("grosser", ["statsn"])
    cache = "#{GemOnDemand::Checkout::DIR}/grosser/statsn/cache/dependencies"
    File.exist?(cache).should == true
    gem_on_demand("--expire grosser/statsn")
    File.exist?(cache).should == false
  end
end
