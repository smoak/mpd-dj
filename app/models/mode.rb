module MPD::DJ
  class Mode

    # === Description
    # Indicates if we are in dj mode
    #
    # === Returns
    # true if we are in dj mode
    # false otherwise
    #
    def self.djing?
      Playlist.length >= 5
    end

  end
end
