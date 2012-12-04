require 'spec_helper'

# This script is not test driven but the spec has been added
# to at least confirm the happy path without having to test manually.

describe Streamio::CLI::App do
  describe "#export" do
    it "should look for videos and audios of target account and download them" do
      stub_request(:get, "https://streamio:passw0rd@streamio.com/api/v1/videos/count").
        to_return(status: 200, body: json(count: 1))

      stub_request(:get, "https://streamio:passw0rd@streamio.com/api/v1/videos?limit=100&skip=0").
        to_return(status: 200, body: webmock_fixture("videos.json"))

      stub_request(:head, "http://d253c4ja9jigvu.cloudfront.net/original_videos/4c50424cb35ea827c0000005_4ce53c17b35ea86d7300000g.mp4").
        to_return(status: 200, headers: {'Content-Length' => 3795530})

      stub_request(:get, "http://d253c4ja9jigvu.cloudfront.net/original_videos/4c50424cb35ea827c0000005_4ce53c17b35ea86d7300000g.mp4").
        to_return(status: 200)

      stub_request(:get, "https://streamio:passw0rd@streamio.com/api/v1/audios/count").
        to_return(status: 200, body: json(count: 1))

      stub_request(:get, "https://streamio:passw0rd@streamio.com/api/v1/audios?limit=100&skip=0").
        to_return(status: 200, body: webmock_fixture("audios.json"))

      stub_request(:head, "http://drtpe3yp3e35w.cloudfront.net/original_audios/4de3a1d0541290fd3000000e_4f96806c505ca25d71000001.mp3").
        to_return(status: 200, headers: {'Content-Length' => 3795530})

      stub_request(:get, "http://drtpe3yp3e35w.cloudfront.net/original_audios/4de3a1d0541290fd3000000e_4f96806c505ca25d71000001.mp3").
        to_return(status: 200)

      subject.options = { username: "streamio", password: "passw0rd" }
      subject.export

      WebMock.should have_requested(:get, "http://d253c4ja9jigvu.cloudfront.net/original_videos/4c50424cb35ea827c0000005_4ce53c17b35ea86d7300000g.mp4")
      WebMock.should have_requested(:get, "http://drtpe3yp3e35w.cloudfront.net/original_audios/4de3a1d0541290fd3000000e_4f96806c505ca25d71000001.mp3")
    end
  end

  private
  def json(hash)
    MultiJson.dump(hash)
  end
end
