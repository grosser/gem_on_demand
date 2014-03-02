module GemOnDemand
  class Checkout
    NotFound = Class.new(Exception)
    NOT_FOUND = "not-found"
    UPDATED_AT = "updated_at"
    DIR = File.expand_path("~/.gem-on-demand/cache")
    CACHE_DURATION = 15 * 60 # for project tags

    attr_accessor :user, :project

    def initialize(user, project)
      self.user = user
      self.project = project
      Utils.ensure_directory(dir)
    end

    def chdir(&block)
      clone_or_refresh
      Dir.chdir(dir, &block)
    end

    def cache
      @cache ||= FileCache.new("#{dir}/cache")
    end

    private

    def dir
      "#{DIR}/#{user}/#{project}"
    end

    def was_not_found?
      cache.read(NOT_FOUND)
    end

    def not_found!
      cache.write(NOT_FOUND, true)
      raise NotFound
    end

    def need_refresh?
      cache.read(UPDATED_AT).to_i < Time.now.to_i - CACHE_DURATION
    end

    def fresh!
      cache.write(UPDATED_AT, Time.now.to_i)
    end

    def clone_or_refresh
      if cloned?
        refresh if need_refresh?
      elsif was_not_found?
        not_found!
      else
        clone
      end
    end

    def refresh
      Dir.chdir(dir) { Utils.sh "git fetch origin" }
      cache.delete Project::DEPENDENCIES
      fresh!
    end

    def clone
      Utils.remove_directory(dir)
      cloned = Utils.sh "git clone git@github.com:#{user}/#{project}.git #{dir}", :fail => :allow
      Utils.ensure_directory(dir)
      if cloned
        fresh!
      else
        not_found!
      end
    end

    def cloned?
      File.directory?("#{dir}/.git")
    end
  end
end
