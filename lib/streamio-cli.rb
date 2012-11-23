require 'net/http'
require 'uri'
require 'fileutils'
require 'thor'
require 'streamio'
require 'ruby-progressbar'
require 'streamio-cli/version'

module Streamio::CLI
  class SlowDownloadError < StandardError
  end

  class App < Thor
    desc "export", "export data from target account"
    method_option :username, :desc => 'api username', :aliases => '-u', :required => true
    method_option :password, :desc => 'api password', :aliases => '-p', :required => true
    method_option :include_transcodings, :aliases => '-i', :type => :boolean
    def export
      configure_streamio_gem
      download_videos
      download_audios
      puts "\nAll files successfully downloaded!"
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
      number_of_items = ::Streamio::Video.count
      current_item = 0
      requests_needed = (number_of_items / 100) + 1

      requests_needed.times do |i|
        ::Streamio::Video.all(:skip => i * 100, :limit => 100).each do |video|
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
      number_of_items = ::Streamio::Audio.count
      current_item = 0
      requests_needed = (number_of_items / 100) + 1

      requests_needed.times do |i|
        ::Streamio::Audio.all(:skip => i * 100, :limit => 100).each do |audio|
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
      http = Net::HTTP.new(uri.host, uri.port)
      size = http.request_head(uri.path)['Content-Length'].to_i
      bytes_loaded = File.exist?(filename) ? File.size(filename) : 0

      if size == bytes_loaded
        puts "  #{progress_bar_title}: Already downloaded..."
        return
      end

      progress_bar = ProgressBar.create(
        :title => "  #{progress_bar_title}",
        :starting_at => 0,
        :total => size,
        :format => "%t: |%B| %P%"
      )

      waiting_for_speed_test = true
      start_time = nil
      http.request_get(uri.path) do |response|
        File.open(filename, "wb") do |file|
          response.read_body do |data|
            progress_bar.progress += data.length
            file << data

            if waiting_for_speed_test
              start_time ||= Time.now
              bytes_loaded_since_connection = progress_bar.progress
              if bytes_loaded_since_connection > 524288
                waiting_for_speed_test = false
                seconds_taken = Time.now - start_time
                bytes_per_second = bytes_loaded_since_connection / seconds_taken
                raise SlowDownloadError if bytes_per_second < 65536
              end
            end
          end
        end
      end
    rescue SlowDownloadError, Timeout::Error => e
      http.finish if http.started?
      progress_bar.stop
      if e.class == SlowDownloadError
        puts "  Slow download detected - retrying!"
      else
        puts "  Download timed out - retrying!"
      end
      retry
    end
  end
end

Streamio::CLI::App.start
