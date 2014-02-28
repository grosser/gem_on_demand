require "spec_helper"

describe GemOnDemand do
  describe ".build_gem" do
    it "can build gem" do
      gem = GemOnDemand.build_gem("grosser", "parallel", "0.9.2")
      gem.size.should >= 2000
    end

    it "can build with outdated gem cert" do
      gem = GemOnDemand.build_gem("grosser", "parallel", "0.8.4")
      gem.size.should >= 2000
    end
  end

  describe ".dependencies" do
    it "lists all dependencies" do
      dependencies = GemOnDemand.dependencies("grosser", ["parallel_tests"])
      dependencies.last.should == {
        :name=>"parallel_tests",
        :number=>"0.9.4",
        :platform=>"ruby",
        :dependencies=>[["parallel", ">= 0"]]
      }
      dependencies.size.should > 50
    end
  end
end
