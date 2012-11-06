require 'net/http'
require 'uri'
require 'thor'
require 'streamio'
require 'ruby-progressbar'
require 'streamio-cli/version'

module Streamio
  class CLI < Thor
    desc "export", "export data from target account"
    method_option :username, :desc => 'api username', :aliases => '-u', :required => true
    method_option :password, :desc => 'api password', :aliases => '-p', :required => true
    method_option :include_transcodings, :aliases => '-i', :type => :boolean
    def export
      configure_streamio_gem
      number_of_videos = Video.count
      current_video = 0
      requests_needed = (number_of_videos / 100) + 1

      requests_needed.times do |i|
        Video.all(:skip => i * 100, :limit => 100).each do |video|
          current_video += 1
          puts "\nVideo #{current_video} / #{number_of_videos}: #{video.title}"

          title = "Original (#{bytes_to_megabytes(video.original_video['size'])})"
          download("http://#{video.original_video['http_uri']}", title)

          next unless options[:include_transcodings]

          video.transcodings.each do |transcoding|
            title = "#{transcoding['title']} (#{bytes_to_megabytes(transcoding['size'])})"
            download("http://#{transcoding['http_uri']}", title)
          end
        end
      end
    end

    private
    def configure_streamio_gem
      Streamio.configure do |c|
        c.username = options[:username]
        c.password = options[:password]
      end
    end

    def bytes_to_megabytes(bytes)
      megabytes = bytes / 1048576.0
      "%.1fMB" % [megabytes]
    end

    def download(url, title)
      url = URI.parse(url)
      filename = File.basename(url.path)
      http = Net::HTTP.new(url.host, url.port)
      size = http.request_head(url.path)['Content-Length'].to_i
      bytes_loaded = 0

      if File.exist?(filename)
        bytes_loaded = File.size(filename)
        if size == bytes_loaded
          puts "  #{title}: Already downloaded..."
          return
        end
      end

      progress_bar = ProgressBar.create(
        :title => "  #{"[Resuming] " if bytes_loaded > 0}#{title}",
        :starting_at => bytes_loaded,
        :total => size,
        :format => "%t: |%B| %e"
      )

      http.request_get(url.path, 'Range' => "bytes=#{bytes_loaded}-") do |response|
        File.open(filename, "a:binary") do |file|
          response.read_body do |data|
            progress_bar.progress += data.length
            file << data
          end
        end
      end
    end
  end
end

Streamio::CLI.start
