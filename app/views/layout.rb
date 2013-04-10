module MPD::DJ
  module Views
    class Layout < Mustache

      def now_playing
        Queue.songs.first
      end

      def songs
        Queue.songs.drop(1)
      end

    end
  end
end
