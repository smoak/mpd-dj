$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

require 'logger'
require 'sinatra/base'
require 'mustache/sinatra'
require 'redis'
require 'mpd'
require 'mpd-dj'
require 'app'
require 'views/layout'
require 'mpd-dj-controller'

$redis = Redis.new(:host => MPD::DJ.config.redis_host, :port => MPD::DJ.config.redis_port)
$mpd = MPD::Controller.new(MPD::DJ.config.mpd_host, MPD::DJ.config.mpd_port)
