require 'models/song'
require 'models/playlist'
require 'models/queue'

module MPD
  module DJ
    class App < Sinatra::Base

      register Mustache::Sinatra

      enable :sessions

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

      before do
        return if ENV['RACK_ENV'] == 'test'

        content_type :json

        session_not_required = request.path_info =~ /\/login/ ||
                               request.path_info =~ /\/auth/ ||
                               request.path_info =~ /\/images\/art\/.*.png/ ||
                               request.path_info =~ /\//

        if session_not_required || @current_user
          true
        else
          login
        end
      end

      def login
      end

      def current_user
        @current_user
      end
      
      get "/" do
        content_type :html
        mustache :index
      end

      get "/dj" do
        content_type :html
        mustache :dj
      end

    end
  end
end
