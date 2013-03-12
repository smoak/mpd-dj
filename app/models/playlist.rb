module MPD::DJ

  # === Description
  # A class representing our current playlist.
  # This stores the complete pool of songs we can
  # choose from in redis.
  class Playlist

    KEY = 'mpd-dj:playlist'

    # === Description
    # Indicates the length of the playlist
    #
    # === Returns
    # Total number of songs in the playlist pool
    def self.length
      $redis.llen "#{KEY}:ids"
    end

    # === Description
    # Gets n random songs from the playlist pool
    #
    # === Parameters
    # +n+ number of random songs to get (default: 1)
    #
    # === Returns
    # n random songs from the playlist pool
    def self.random(n = 1)
    end

  end
end

