require 'sinatra/base'
require 'gem_on_demand'

module GemOnDemand
  class Server < Sinatra::Base
    set :port, 7154
    set :lock, true # multi threading is not supported when doing chdir foo

    get '/:username/api/v1/dependencies' do
      user = params[:username]
      if gems = params[:gems]
        dependencies = GemOnDemand.dependencies(user, gems.split(","))
        if params[:debug]
          dependencies.inspect
        else
          Marshal.dump(dependencies)
        end
      else
        "" # first request wants no response ...
      end
    end

    get '/:username/gems/:project-:version.gem' do
      user = params[:username]
      project = params[:project]
      version = params[:version]
      GemOnDemand.build_gem(user, project, version)
    end
  end
end
