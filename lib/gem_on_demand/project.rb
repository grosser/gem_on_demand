module GemOnDemand
  class Project
    MAX_VERSIONS = 50 # some projects just have a million versions ...
    DEPENDENCIES = "dependencies"
    VERSION_REX = /^v?\d+\.\d+\.\d+(\.\w+)?$/ # with or without v and pre-release (cannot do others or we get: 'Malformed version number string 1.0.0-rails3' from bundler)

    attr_accessor :user, :name, :cache

    def initialize(user, name, cache)
      self.user = user
      self.name = name
      self.cache = cache
    end

    def dependencies
      cache.fetch DEPENDENCIES do
        versions.last(MAX_VERSIONS).map do |version|
          next unless dependencies = dependencies_for_version(version)
          {
            :name => name,
            :number => version.sub(/^v/, ""),
            :platform => "ruby",
            :dependencies => dependencies
          }
        end.compact
      end
    end

    def build_gem(version)
      cache.fetch("gem-#{version}") do
        checkout_version("v#{version}")
        gemspec = "#{name}.gemspec"
        Utils.remove_signing(gemspec)
        Utils.sh("gem build #{gemspec}")
        File.read("#{name}-#{version}.gem")
      end
    end

    private

    def dependencies_for_version(version)
      cache.fetch "dependencies-#{version}" do
        checkout_version(version)
        result = Utils.sh(%{ruby -e 'print Marshal.dump(eval(File.read("#{name}.gemspec")).runtime_dependencies.map{|d| [d.name, d.requirement.to_s]})'}, :fail => :allow)
        Marshal.load(result) if result
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
