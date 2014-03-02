module GemOnDemand
  class Checkout
    NOT_FOUND = "not-found"
    UPDATED_AT = "updated_at"
    DIR = File.expand_path("~/.gem-on-demand/cache")
    CACHE_DURATION = 15 * 60 # for project tags

    attr_accessor :user, :project

    def initialize(user, project)
      self.user = user
      self.project = project
    end

    def inside(&block)
      dir = "#{DIR}/#{user}"
      Utils.ensure_directory(dir)
      Dir.chdir(dir) do
        clone_or_refresh
        Dir.chdir(project.name, &block)
      end
    end

    private

    def not_found?
      File.directory?(project.name) && Dir.chdir(project.name) { project.cache(NOT_FOUND) }
    end

    def not_found!
      Utils.ensure_directory(project.name)
      Dir.chdir(project.name) { project.cache(NOT_FOUND, true) }
    end

    def refreshed!
      Dir.chdir(project.name) do
        project.cache(UPDATED_AT, Time.now.to_i)
      end
    end

    def refresh?
      Dir.chdir(project.name) { project.cache(UPDATED_AT).to_i } < Time.now.to_i - CACHE_DURATION
    end

    def clone_or_refresh
      if File.directory?("#{project.name}/.git")
        if refresh?
          Dir.chdir(project.name) do
            Utils.sh "git fetch origin"
            project.expire_key Project::DEPENDENCIES
          end
          refreshed!
        end
      elsif not_found?
        raise Project::NotFound
      else
        Utils.remove_directory(project.name)
        found = Utils.sh "git clone git@github.com:#{user}/#{project.name}.git", :fail => :allow
        if found
          refreshed!
        else
          not_found!
          raise Project::NotFound
        end
      end
    end
  end
end
