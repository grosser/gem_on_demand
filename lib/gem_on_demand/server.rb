require 'sinatra/base'
require 'gem_on_demand'

module GemOnDemand
  class Server < Sinatra::Base
    get '/:username/api/v1/dependencies' do
      user = params[:username]
      if params[:gems]
        dependencies = GemOnDemand.dependencies(user, params[:gems].split(","))
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
