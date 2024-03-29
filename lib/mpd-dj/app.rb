require 'mpd'
require 'logger'

module MPD
  module DJ
    class Application

      DEFAULTS = {
        :host => "localhost",
        :port => 6600,
        :upcoming => 20, # how many songs should be on the list for after the current track.
        :recent => 0 # how many songs before the current song are kept on the playlist, with 0 being "Remove the song as soon as it's done playing"
      }

      SimpleSongStruct = Struct.new(:file, :playlist_pos, :id)

      def initialize(options = {})
        # convert to symbols because those are cooler
        @options = options.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        @options = DEFAULTS.merge(@options)
        # 0 probably doesn't work well here, but 1 would be only the next song.
        @options[:upcoming] = 1 unless @options[:upcoming] > 0
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::DEBUG
        @last_song = SimpleSongStruct.new
        @current_song = SimpleSongStruct.new
        @update_song_cache = true
        @client = MPD::Controller.new(@options[:host], @options[:port])
      end

      ##
      # Called when a new status is received from mpd
      #
      # This can be database, update, stored_playlist,
      # playlist, player, mixer, output, options,
      # sticker, subscription, message
      #
      # See http://www.musicpd.org/doc/protocol/ch03.html#idp125872
      # for more information on status messages.
      #
      # This is where we do the bulk of our work
      # to figure out how many songs to remove or add
      def new_status_callback(subsystem)
        if subsystem == :database
          @logger.debug("marking song cache for updating")
          @update_song_cache = true
        end
        new_status = @client.status
        @logger.debug "new status from mpd: #{subsystem}"

        # if the playlist was cleared, well get a new status
        # but we dont want to do anything in that case
        return if new_status.playlist.current.nil?

        @last_song = @current_song
        @current_song = song_from_status(new_status)

        if @last_song.id != @current_song.id 
          @logger.debug("got new song: #{@current_song}")
          playlist_len = @client.playlist.length 
          before_pos = @last_song.playlist_pos
          after = playlist_len - @current_song.playlist_pos
          if @current_song.playlist_pos > @options[:recent]
            count = @current_song.playlist_pos - @options[:recent]
            remove_songs(count)
          end
          if after < @options[:upcoming]
            add_songs(songs.sample(1))
          end

        end
        
      end

      ##
      # Returns all songs in the database
      def songs
        # memoize for now since this can be expensive.
        if @songs.nil? || @update_song_cache
          @songs = @client.do_and_raise_if_needed(:listall, "/").select { |name, _|
            name == :file
          }.map { |name, value|
            MPD::Controller::Database::Song.from_data({ name => value }, @client)
          }
          @update_song_cache = false
        end
        @songs

      end

      ##
      # Adds songs to the end of the playlist
      def add_songs(songs)
        @logger.debug("Adding #{songs.length} random songs")
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
        @logger.debug("Removing #{how_many} songs")
        how_many.times { |n|
          @client.playlist.delete(0)
        }
      end

      ##
      # Initializes the playlist
      #
      # playlist init boils down to:
      # 1. if sizeof playlist < upcoming then add upcoming - sizeof playlist random songs
      # 2. if sizeof playlist > upcoming then remove :recent from the top
      # 3. ensure random playmode is not on
      # 4. if stopped, then play the first song in the playlist
      # 5. if paused, then unpause
      def initialize_playlist
        playlist_size = @client.playlist.length

        # Ensure our playlist has enough songs
        if playlist_size < @options[:upcoming]
          songs_to_add = @options[:upcoming] - playlist_size
          add_songs songs.sample(songs_to_add)
        end

        @client.toggle.no_random! if @client.status.random?
        @client.player.play(:position => -1) if @client.status == :stop
        @client.player.unpause if @client.status == :pause

        @current_song = song_from_status(@client.status)

        # check if we need to remove any songs based on the
        # amount of recent songs we want to keep
        # This is the case where we get started when the current song
        # is already past the very first song (e.g. its halfway through)
        if @current_song.playlist_pos > @options[:recent]
          count = @current_song.playlist_pos - @options[:recent]
          remove_songs(count)
        end

        @logger.debug("Current Song: #{@current_song}")

      end

      def song_from_status(status)
        song = SimpleSongStruct.new
        song.file = status.song.file
        song.playlist_pos = status.playlist.current.position
        song.id = status.playlist.current.id
        return song
      end

      def run!
        # When a song is finished playing it is removed from the playlist, and the playlist is meant to always have a certain number of items in it.
        # When there aren't enough songs in the playlist, one is randomly chosen from the library and put on the end of the list.
        initialize_playlist
        @client.loop do |r|
          new_status_callback r
        end
        return 0
      end

    end
  end
end
