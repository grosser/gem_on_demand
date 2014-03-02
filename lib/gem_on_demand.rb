require 'tmpdir'
require 'gem_on_demand/checkout'
require 'gem_on_demand/project'
require 'gem_on_demand/utils'
require 'gem_on_demand/file_cache'

module GemOnDemand
  HEAVY_FORKED = ["rails", "mysql", "mysql2"]

  class << self
    def build_gem(user, project, version)
      checkout = Checkout.new(user, project)
      checkout.chdir do
        Project.new(user, project, checkout.cache).build_gem(version)
      end
    end

    def dependencies(user, gems)
      (gems - HEAVY_FORKED).map do |project|
        checkout = Checkout.new(user, project)
        begin
          checkout.chdir do
            Project.new(user, project, checkout.cache).dependencies
          end
        rescue Checkout::NotFound
          []
        end
      end.flatten
    end

    # expire update related caches so next run gets fresh tags + versions
    def expire(user, project)
      checkout = Checkout.new(user, project)
      [
        Checkout::UPDATED_AT,
        Checkout::NOT_FOUND,
        Project::DEPENDENCIES
      ].each do |key|
        checkout.cache.expire key
      end
    end
  end
end
