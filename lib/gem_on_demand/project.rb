module GemOnDemand
  class Project
    MAX_VERSIONS = 50 # some projects just have a million versions ...
    DEPENDENCIES = "dependencies"
    NOT_FOUND = "not-found"
    UPDATED_AT = "updated_at"
    CHECKOUT_DIR = File.expand_path("~/.gem-on-demand/cache")
    DATA_CACHE = "cache"
    CACHE_DURATION = 15 * 60 # for project tags
    NotFound = Class.new(Exception)
    VERSION_REX = /^v?\d+\.\d+\.\d+(\.\w+)?$/ # with or without v and pre-release (cannot do others or we get: 'Malformed version number string 1.0.0-rails3' from bundler)

    attr_accessor :user, :name

    def initialize(user, name)
      self.user = user
      self.name = name
    end

    def dependencies
      inside_checkout do
        cache DEPENDENCIES do
          versions.last(MAX_VERSIONS).map do |version|
            next unless dependencies = dependencies_for_version(version)
            {
              :name => name,
              :number => version.sub(/^v/, ""),
              :platform => "ruby",
              :dependencies => Marshal.load(dependencies)
            }
          end.compact
        end
      end
    rescue NotFound
      []
    end

    def build_gem(version)
      inside_checkout do
        cache("gem-#{version}") do
          checkout_version("v#{version}")
          gemspec = "#{name}.gemspec"
          Utils.remove_signing(gemspec)
          sh("gem build #{gemspec}")
          File.read("#{project}-#{version}.gem")
        end
      end
    end

    def expire
      dir = "#{CHECKOUT_DIR}/#{user}/#{name}"
      return unless File.directory?(dir)
      Dir.chdir dir do
        expire_key UPDATED_AT
        expire_key NOT_FOUND
        expire_key DEPENDENCIES
      end
    end

    private

    def dependencies_for_version(version)
      cache "dependencies-#{version}" do
        checkout_version(version)
        Utils.sh(%{ruby -e 'print Marshal.dump(eval(File.read("#{name}.gemspec")).runtime_dependencies.map{|d| [d.name, d.requirement.to_s]})'}, :fail => :allow)
      end
    end

    def versions
      Utils.sh("git tag").split($/).grep(VERSION_REX)
    end

    def inside_checkout(&block)
      dir = "#{CHECKOUT_DIR}/#{user}"
      Utils.ensure_directory(dir)
      Dir.chdir(dir) do
        clone_or_refresh
        Dir.chdir(name, &block)
      end
    end

    def cache(file, value = nil, &block)
      Utils.ensure_directory(DATA_CACHE)
      file = "#{DATA_CACHE}/#{file}"
      if block
        if File.exist?(file)
          Marshal.load(File.read(file))
        else
          result = yield
          File.write(file, Marshal.dump(result))
          result
        end
      else
        if value.nil?
          Marshal.load(File.read(file)) if File.exist?(file)
        else
          File.write(file, Marshal.dump(value))
        end
      end
    end

    def expire_key(key)
      key = "#{DATA_CACHE}/#{key}"
      File.unlink(key) if File.exist?(key)
    end

    # on user folder level
    def not_found?
      File.directory?(name) && Dir.chdir(name) { cache(NOT_FOUND) }
    end

    # on user folder level
    def not_found!
      Utils.ensure_directory(name)
      Dir.chdir(name) { cache(NOT_FOUND, true) }
    end

    # on user folder level
    def refreshed!
      Dir.chdir(name) { cache(UPDATED_AT, Time.now.to_i) }
    end

    # on user folder level
    def refresh?
      Dir.chdir(name) { cache(UPDATED_AT).to_i } < Time.now.to_i - CACHE_DURATION
    end

    # on user folder level
    def clone_or_refresh
      if File.directory?("#{name}/.git")
        if refresh?
          Dir.chdir(name) do
            Utils.sh "git fetch origin"
            expire_key DEPENDENCIES
          end
          refreshed!
        end
      elsif not_found?
        raise NotFound
      else
        Utils.remove_directory(name)
        found = Utils.sh "git clone git@github.com:#{user}/#{name}.git", :fail => :allow
        if found
          refreshed!
        else
          not_found!
          raise NotFound
        end
      end
    end

    def checkout_version(version)
      Utils.sh("git checkout #{version} --force")
    end
  end
end
