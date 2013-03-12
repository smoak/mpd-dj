require File.expand_path(File.dirname(__FILE__) + '/app/boot')
# fork our controller script
pid = fork {
  MPD::DJ::Controller.run!
}
# dont wait for it
Process.detach(pid)
run MPD::DJ::App
