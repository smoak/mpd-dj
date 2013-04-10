require File.expand_path(File.dirname(__FILE__) + '/app/boot')
require 'sprockets'

stylesheets = Sprockets::Environment.new
stylesheets.append_path 'app/frontend/styles'

javascripts = Sprockets::Environment.new
javascripts.append_path 'app/frontend/scripts'

images = Sprockets::Environment.new
images.append_path 'app/frontend/images'


# fork our controller script
#pid = fork {
#  MPD::DJ::Controller.run!
#}
# dont wait for it
#Process.detach(pid)
map("/css") { run stylesheets }
map("/js") { run javascripts }
map("/img") { run images }
map("/") { run MPD::DJ::App }
