module MPD::DJ
  class Song
    attr_accessor :file

    attr_accessor :artist

    attr_accessor :title

    attr_accessor :album

    def initialize(options)
      @file = options[:file]
      @artist = options[:artist]
      @title = options[:title]
      @album = options[:album]
    end

    def self.from_mpd(s)
      new :file => s.file,
          :artist => s.artist,
          :title => s.title,
          :album => s.album
    end

    def to_hash
      { 
        :file => file,
        :artist => artist,
        :title => title,
        :album => album
      }
    end

    def to_json
      { 
        :file => file,
        :artist => artist,
        :title => title,
        :album => album
      }
    end
  end

end
