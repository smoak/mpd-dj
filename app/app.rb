require 'models/playlist'
require 'models/mode'

module MPD
  module DJ
    class App < Sinatra::Base

      register Mustache::Sinatra

      configure :production, :development do
        enable :logging
      end

      dir = File.dirname(File.expand_path(__FILE__))
      set :public_folder, "#{dir}/frontend/public"
      set :static, true
      set :mustache, {
        :namespace => MPD::DJ,
        :templates => "#{dir}/templates",
        :views => "#{dir}/views"
      }
      
      get "/" do
        content_type :html
        if Mode.djing?
          mustache :index
        else
          mustache :setup
        end
      end

    end
  end
end
