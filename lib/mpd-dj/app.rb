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
         
        @logger.debug "new status from mpd: #{new_status}"

        if !new_status.playlist.current.nil? && @current_song.id != new_status.playlist.current.id
          @current_song = new_status.playlist.current
          @logger.debug("got new song: #{new_status.song.file} id: #{@current_song.id}")
#          add_songs(songs.sample(@options[:enqueue_count])) if new_status.playlistlength - @options[:enqueue_count]
#          remove_songs(new_status.playlistlength - @options[:keep])
          # enqueue :enqueue_count songs if we are at playlist_len - :enqueue_count
          # remove playlist_len - :keep songs starting from the top of the playlist
          #remove_songs(1)
          #add_songs(songs.sample(@options[:enqueue_count]))
        end
        
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
        commandProc = Proc.new { |_|
          songs.each { |s|
            @commands << ::MPD::Protocol::Command.new(:addid, s.file)
          }
        }
        @client.do &commandProc
      end

      ##
      # Removes songs from the top of the playlist (i.e. already played songs)
      def remove_songs(how_many)
        how_many.times { |n|
          @client.playlist.delete(0)
        }
      end

      ##
      # Initializes the playlist
      #
      # playlist init boils down to:
      # 1. if sizeof playlist < keep then add keep - sizeof playlist random songs
      # 2. if sizeof playlist > keep then remove sizeof playlist - keep from the top
      # 3. ensure random playmode is not on
      # 4. if stopped, then play the first song in the playlist
      # 5. if paused, then unpause
      def initialize_playlist
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
        @client.toggle.no_random! if @client.status.random?
        @client.player.play(:position => -1) if @client.status == :stop
        @client.player.unpause if @client.status == :pause
        @current_song = @client.status.playlist.current
        @logger.debug("Current Song: #{@client.status.song.file}")
      end

      def run!
        initialize_client
        initialize_playlist
        @client.loop do 
          new_status_callback @client.status
        end
        return 0
      end

    end
  end
end
