require 'mpd'
require 'logger'

module MPD
  module DJ
    class Application

      DEFAULTS = {
        :host => "localhost",
        :port => 6600,
        :enqueue_count => 2, # Number of songs to enqueue before the current one
        :keep => 10 # Number of already played songs to keep in the playlist
      }


      def initialize(options = {})
        # convert to symbols because those are cooler
        @options = options.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        @options = DEFAULTS.merge(@options)
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::DEBUG
      end

      def initialize_client
        @client = MPD::Controller.new(@options[:host], @options[:port])
      end

      def new_status_callback(new_status)
        # This is where we do all our work
        #
         
        puts "new status from mpd: #{new_status}"
      end

      ##
      # Returns all songs in the database
      def songs
        # memoize for now since this can be expensive.
        # TODO: figure out when to update this "cache"
        if @songs.nil?
          @songs = @client.do_and_raise_if_needed(:listall, "/").select { |name, _|
            name == :file
          }.map { |name, value|
            MPD::Controller::Database::Song.from_data({ name => value }, @client)
          }
        end
        @songs

      end

      def add_songs(songs)
        songs.each { |s|
          @client.playlist.add(s.file)
        }
      end

      def remove_songs(how_many)
        how_many.times { |n|
          @client.playlist.delete(1)
        }
      end

      def initialize_playlist
        # playlist init boils down to:
        # 1. if sizeof playlist < keep then add keep - sizeof playlist random songs
        # 2. if sizeof playlist > keep then remove sizeof playlist - keep from the top
        # 3. ensure random playmode is not on
        playlist_size = @client.playlist.length
        if playlist_size < @options[:keep]
          songs_to_add = @options[:keep] - playlist_size
          @logger.debug("Adding #{songs_to_add} random songs")
          add_songs songs.sample(songs_to_add)
        end
        if playlist_size > @options[:keep]
          songs_to_remove = playlist_size - @options[:keep]
          @logger.debug("Removing #{songs_to_remove} songs")
          remove_songs songs_to_remove
        end
      end

      def run!
        initialize_client
        initialize_playlist
        @logger.debug("Status: #{@client.status}")
        @client.player.play(0) if @client.status == :pause
        @client.loop do 
          new_status_callback @client.status
        end
        return 0
      end

    end
  end
end
