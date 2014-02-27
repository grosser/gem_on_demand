require 'sinatra'
require 'tmpdir'

def sh(command)
  puts command
  result = `#{command}`
  raise unless $?.success?
  result
end

def dependencies(user, gems)
  Dir.mktmpdir do |dir|
    gems.map do |project|
      Dir.chdir(dir) do
        sh "git clone https://github.com/#{user}/#{project}.git"
        Dir.chdir(project) do
          versions = sh("git tag").split($/).grep(/^v\d+\.\d\.\d$/)
          puts "VERSIONS #{versions}"
          versions.last(2).map do |version|
            sh("git checkout #{version}")
            dependencies = sh(%{ruby -e 'print Marshal.dump(eval(File.read("#{project}.gemspec")).runtime_dependencies.map{|d| [d.name, d.requirement]})'})
            {
              :name => project,
              :number => version[1..-1],
              :platform => "ruby",
              :dependencies => Marshal.load(dependencies)
            }
          end
        end
      end
    end.flatten
  end
end

get '/:username/api/v1/dependencies' do
  user = params[:username]
  if params[:gems]
    dependencies = dependencies(user, params[:gems].split(","))
    if params[:debug]
      dependencies.inspect
    else
      Marshal.dump(dependencies)
    end
  else
    "" # first request wants no response ...
  end
end
