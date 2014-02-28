require 'tmpdir'

module GemOnDemand
  class << self
    def build_gem(user, project, version)
      clone_project(user, project) do
        checkout_version("v#{version}")
        gemspec = "#{project}.gemspec"
        remove_signing(gemspec)
        sh("gem build #{gemspec}")
        File.read("#{project}-#{version}.gem")
      end
    end

    def dependencies(user, gems)
      gems.map do |project|
        clone_project(user, project) do
          versions = sh("git tag").split($/).grep(/^v\d+\.\d\.\d$/)
          puts "VERSIONS #{versions}"
          versions.last(2).map do |version|
            checkout_version(version)
            dependencies = sh(%{ruby -e 'print Marshal.dump(eval(File.read("#{project}.gemspec")).runtime_dependencies.map{|d| [d.name, d.requirement.to_s]})'})
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

    def sh(command)
      puts command
      result = `#{command}`
      raise unless $?.success?
      result
    end

    def clone_project(user, project, &block)
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          sh "git clone https://github.com/#{user}/#{project}.git"
          Dir.chdir(project, &block)
        end
      end
    end

    def checkout_version(version)
      sh("git checkout #{version}")
    end

    # ERROR:  While executing gem ... (Gem::Security::Exception)
    # certificate /CN=michael/DC=grosser/DC=it not valid after 2014-02-03 18:13:11 UTC
    def remove_signing(gemspec)
      File.write(gemspec, File.read(gemspec).gsub(/.*\.(signing_key|cert_chain).*/, ""))
    end
  end
end
