module MPD::DJ

  def self.config
    OpenStruct.new \
      :mpd_host => yaml['mpd_host'],
      :mpd_port => yaml['mpd_port'],
      :redis_host => yaml['redis_host'],
      :redis_port => yaml['redis_port'],
      :timeout => yaml['timeout'],
      :reconnect => yaml['reconnect'],
      :recent => yaml['recent'],
      :upcoming => yaml['upcoming']
      
  end

  private

    def self.yaml
      if File.exist?('config/mpd-dj.yml')
        @yaml ||= YAML.load_file('config/mpd-dj.yml')
      else
        {}
      end
    end
end
