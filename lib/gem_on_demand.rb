require 'tmpdir'

module GemOnDemand
  CACHE = "cache"
  CACHE_DURATION = 30 # seconds

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
      gems.map do |project|
        inside_of_project(user, project) do
          versions = sh("git tag").split($/).grep(/^v\d+\.\d\.\d$/)
          versions.map do |version|
            dependencies = cache "dependencies-#{version}" do
              checkout_version(version)
              sh(%{ruby -e 'print Marshal.dump(eval(File.read("#{project}.gemspec")).runtime_dependencies.map{|d| [d.name, d.requirement.to_s]})'})
            end
            {
              :name => project,
              :number => version[1..-1],
              :platform => "ruby",
              :dependencies => Marshal.load(dependencies)
            }
          end
        end
      end.flatten
    end

    private

    def cache(file)
      ensure_cache
      file = "#{CACHE}/#{file}"
      if File.exist?(file)
        Marshal.load(File.read(file))
      else
        result = yield
        File.write(file, Marshal.dump(result))
        result
      end
    end

    def sh(command)
      puts command
      result = `#{command}`
      raise "Command failed: #{result}" unless $?.success?
      result
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
        if refresh?(project)
          Dir.chdir(project) { sh "git fetch origin" }
          refreshed!(project)
        end
      else
        sh "git clone git@github.com:#{user}/#{project}.git"
        refreshed!(project)
      end
    end

    def refreshed!(project)
      File.write(updated(project), Time.now.to_i)
    end

    def refresh?(project)
      File.read(updated(project)).to_i < Time.now.to_i - CACHE_DURATION
    end

    def updated(project)
      "#{project}.updated_at"
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
