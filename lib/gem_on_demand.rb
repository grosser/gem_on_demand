require 'tmpdir'
require 'gem_on_demand/project'

module GemOnDemand
  HEAVY_FORKED = ["rails", "mysql", "mysql2"]

  class << self
    def build_gem(user, project, version)
      Project.new(user, project).build_gem(version)
    end

    def dependencies(user, gems)
      (gems - HEAVY_FORKED).map do |project|
        Project.new(user, project).dependencies
      end.flatten
    end

    def expire(user, project)
      Project.new(user, project).expire
    end
  end
end
