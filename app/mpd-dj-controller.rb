module MPD::DJ
  class Controller

    def self.run!
      $mpd.loop do |r|
        new_status_callback r
      end
      return 0
    end

    private

    def self.new_status_callback(subsystem)
      puts logger
    end

  end
end
