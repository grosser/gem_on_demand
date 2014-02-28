require "spec_helper"

describe GemOnDemand do
  let(:config) { YAML.load_file("spec/config.yml") if File.exist?("spec/config.yml") }

  def with_config
    if config
      yield
    else
      pending "No spec/config.yml"
    end
  end

  describe ".build_gem" do
    it "can build gem" do
      gem = GemOnDemand.build_gem("grosser", "parallel", "0.9.2")
      gem.size.should >= 2000
    end

    it "can build with outdated gem cert" do
      gem = GemOnDemand.build_gem("grosser", "parallel", "0.8.4")
      gem.size.should >= 2000
    end

    it "is fast when cached" do
      GemOnDemand.build_gem("grosser", "parallel", "0.9.2")
      t = Benchmark.realtime { GemOnDemand.build_gem("grosser", "parallel", "0.9.2") }
      t.should < 0.01
    end
  end

  describe ".dependencies" do
    it "lists all dependencies" do
      dependencies = GemOnDemand.dependencies("grosser", ["parallel_tests"])
      dependencies.last.should include(
        :name=>"parallel_tests",
        :platform=>"ruby",
        :dependencies=>[["parallel", ">= 0"]]
      )
      dependencies.size.should >= 50
    end

    it "lists dependencies for private repo" do
      with_config do
        dependencies = GemOnDemand.dependencies(config[:private][:user], [config[:private][:project]])
        dependencies.last.should include config[:private][:dependencies]
      end
    end

    it "lists nothing when gems are not found" do
      dependencies = GemOnDemand.dependencies("grosser", ["missing"])
      dependencies.should == []
    end

    it "does not list broken gem versions" do
      dependencies = GemOnDemand.dependencies("zendesk", ["kasket"])
      dependencies.size.should > 10
      versions = dependencies.map { |d| d[:number] }
      versions.should include "3.1.0"
      versions.should_not include "v0.9.0" # requires activerecord from gemspec
    end

    it "remembers unfound gems" do
      dependencies = GemOnDemand.dependencies("grosser", ["does_not_exist"])
      dependencies.should == []
      t = Benchmark.realtime { GemOnDemand.dependencies("grosser", ["does_not_exist"]) }
      t.should < 0.001
    end

    it "does not know rails, because it's a giant repo with tons of forks" do
      dependencies = GemOnDemand.dependencies("grosser", ["rails"])
      dependencies.should == []
    end
  end
end
