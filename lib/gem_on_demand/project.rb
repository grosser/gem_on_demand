module GemOnDemand
  class Project
    MAX_VERSIONS = 50 # some projects just have a million versions ...
    DEPENDENCIES = "dependencies"
    DATA_CACHE = "cache"
    NotFound = Class.new(Exception)
    VERSION_REX = /^v?\d+\.\d+\.\d+(\.\w+)?$/ # with or without v and pre-release (cannot do others or we get: 'Malformed version number string 1.0.0-rails3' from bundler)

    attr_accessor :user, :name

    def initialize(user, name)
      self.user = user
      self.name = name
    end

    def dependencies
      checkout.inside do
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
      checkout.inside do
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
      dir = "#{Checkout::DIR}/#{user}/#{name}"
      return unless File.directory?(dir)
      Dir.chdir dir do
        expire_key Checkout::UPDATED_AT
        expire_key Checkout::NOT_FOUND
        expire_key DEPENDENCIES
      end
    end

    def expire_key(key)
      key = "#{DATA_CACHE}/#{key}"
      File.unlink(key) if File.exist?(key)
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

    private

    def checkout
      @checkout ||= Checkout.new(user, self)
    end

    def dependencies_for_version(version)
      cache "dependencies-#{version}" do
        checkout_version(version)
        Utils.sh(%{ruby -e 'print Marshal.dump(eval(File.read("#{name}.gemspec")).runtime_dependencies.map{|d| [d.name, d.requirement.to_s]})'}, :fail => :allow)
      end
    end

    def checkout_version(version)
      Utils.sh("git checkout #{version} --force")
    end

    def versions
      Utils.sh("git tag").split($/).grep(VERSION_REX)
    end
  end
end
