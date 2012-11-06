require 'net/http'
require 'uri'
require 'fileutils'
require 'thor'
require 'streamio'
require 'ruby-progressbar'
require 'excon'
require 'streamio-cli/version'

module Streamio
  class CLI < Thor
    desc "export", "export data from target account"
    method_option :username, :desc => 'api username', :aliases => '-u', :required => true
    method_option :password, :desc => 'api password', :aliases => '-p', :required => true
    method_option :include_transcodings, :aliases => '-i', :type => :boolean
    def export
      configure_streamio_gem
      download_videos
      download_audios
    rescue SocketError
      puts "[ERROR]"
      puts "Could not connect to the internet, please check your connection and try again."
      exit
    end

    private
     def configure_streamio_gem
      Streamio.configure do |c|
        c.username = options[:username]
        c.password = options[:password]
      end
    end

    def download_videos
      number_of_items = Video.count
      current_item = 0
      requests_needed = (number_of_items / 100) + 1

      requests_needed.times do |i|
        Video.all(:skip => i * 100, :limit => 100).each do |video|
          current_item += 1
          puts "\nVideo #{current_item} / #{number_of_items} - #{video.title} - #{video.id}"

          path = FileUtils.mkdir_p("streamio-export/videos/#{video.id}").first
          progress_bar_title = "Original (#{bytes_to_megabytes(video.original_video['size'])})"
          File.open("#{path}/#{video.id}.json", "w:utf-8") { |file| file.write(video.attributes.to_json) }
          download("http://#{video.original_video['http_uri']}", path, progress_bar_title)

          next unless options[:include_transcodings]

          video.transcodings.each do |transcoding|
            progress_bar_title = "#{transcoding['title']} (#{bytes_to_megabytes(transcoding['size'])})"
            download("http://#{transcoding['http_uri']}", path, progress_bar_title)
          end
        end
      end
    end

    def download_audios
      number_of_items = Audio.count
      current_item = 0
      requests_needed = (number_of_items / 100) + 1

      requests_needed.times do |i|
        Audio.all(:skip => i * 100, :limit => 100).each do |audio|
          current_item += 1
          puts "\nAudio #{current_item} / #{number_of_items}: #{audio.title}"

          path = FileUtils.mkdir_p("streamio-export/audios/#{audio.id}").first
          progress_bar_title = "Original (#{bytes_to_megabytes(audio.original_file['size'])})"
          File.open("#{path}/#{audio.id}.json", "w:utf-8") { |file| file.write(audio.attributes.to_json) }
          download("http://#{audio.original_file['http_uri']}", progress_bar_title)
        end
      end
    end

    def bytes_to_megabytes(bytes)
      megabytes = bytes / 1048576.0
      "%.1fMB" % [megabytes]
    end

    def download(url, path, progress_bar_title)
      uri = URI.parse(url)
      filename = "#{path}/#{File.basename(uri.path)}"
      size = Excon.head(url).headers['Content-Length'].to_i

      if File.exist?(filename) && size == File.size(filename)
        puts "  #{progress_bar_title}: Already downloaded..."
        return
      end

      progress_bar = ProgressBar.create(
        :title => "  #{progress_bar_title}",
        :starting_at => 0,
        :total => size,
        :format => "%t: |%B| %P%"
      )

      File.open(filename, "w:binary") do |file|
        Excon.get(url, :response_block => lambda do |data, remaining_bytes, total_bytes|
          progress_bar.progress += data.length
          file << data
        end)
      end
    end
  end
end

Streamio::CLI.start
