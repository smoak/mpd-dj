module MPD::DJ
  module Views
    class DJ < Layout
      def songs
        Queue.songs
      end
    end
  end
end

