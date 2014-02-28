require 'tmpdir'

module GemOnDemand
  CACHE = "cache"
  CACHE_DURATION = 30 # seconds
  ProjectNotFound = Class.new(Exception)
  VERSION_REX = /^v?\d+\.\d\.\d(\.\w+)?$/ # with or without v and pre-release (cannot do others or we get: 'Malformed version number string 1.0.0-rails3' from bundler)
  HEAVY_FORKED = ["rails"]
  MAX_VERSIONS = 50 # some projects just have a million versions ...

  class << self
    def build_gem(user, project, version)
      inside_of_project(user, project) do
        checkout_version("v#{version}")
        gemspec = "#{project}.gemspec"
        remove_signing(gemspec)
        sh("gem build #{gemspec}")
        File.read("#{project}-#{version}.gem")
      end
    end

    def dependencies(user, gems)
      (gems - HEAVY_FORKED).map do |project|
        begin
          inside_of_project(user, project) do
            versions = sh("git tag").split($/).grep(VERSION_REX)
            versions.last(MAX_VERSIONS).map do |version|
              dependencies = cache "dependencies-#{version}" do
                checkout_version(version)
                sh(%{ruby -e 'print Marshal.dump(eval(File.read("#{project}.gemspec")).runtime_dependencies.map{|d| [d.name, d.requirement.to_s]})'}, :fail => :allow)
              end
              next unless dependencies # gemspec error
              {
                :name => project,
                :number => version.sub(/^v/, ""),
                :platform => "ruby",
                :dependencies => Marshal.load(dependencies)
              }
            end.compact
          end
        rescue ProjectNotFound
          []
        end
      end.flatten
    end

    private

    def cache(file, value = nil, &block)
      ensure_cache
      file = "#{CACHE}/#{file}"
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

    def sh(command, options = { })
      puts command
      result = `#{command}`
      if $?.success?
        result
      elsif options[:fail] == :allow
        false
      else
        raise "Command failed: #{result}"
      end
    end

    def inside_of_project(user, project, &block)
      ensure_cache
      Dir.chdir(CACHE) do
        clone_or_refresh_project(user, project)
        Dir.chdir(project, &block)
      end
    end

    def ensure_cache
      Dir.mkdir(CACHE) unless File.directory?(CACHE)
    end

    def clone_or_refresh_project(user, project)
      if File.directory?(project)
        if File.exist?("#{project}/not-found")
          raise ProjectNotFound
        elsif refresh?(project)
          Dir.chdir(project) { sh "git fetch origin" }
          refreshed!(project)
        end
      else
        success = sh "git clone git@github.com:#{user}/#{project}.git", :fail => :allow
        if success
          refreshed!(project)
        else
          # mark it as not found
          Dir.mkdir(project)
          File.write("#{project}/not-found", "")
          raise ProjectNotFound
        end
      end
    end

    def refreshed!(project)
      Dir.chdir(project) { cache("updated_at", Time.now.to_i) }
    end

    def refresh?(project)
      Dir.chdir(project) { cache("updated_at").to_i } < Time.now.to_i - CACHE_DURATION
    end

    def checkout_version(version)
      sh("git checkout #{version} --force")
    end

    # ERROR:  While executing gem ... (Gem::Security::Exception)
    # certificate /CN=michael/DC=grosser/DC=it not valid after 2014-02-03 18:13:11 UTC
    def remove_signing(gemspec)
      File.write(gemspec, File.read(gemspec).gsub(/.*\.(signing_key|cert_chain).*/, ""))
    end
  end
end
