module MPD::DJ
  # === Description
  # Represents the play queue. This will be a subset
  # of the playlist. This is stored in mpd
  class Queue

    def self.length
      $mpd.playlist.length
    end

    def self.add_song(song)
      puts logger

    end

  end
end
