require 'thor'
require 'streamio'

require 'streamio-cli/version'

module Streamio
  class CLI < Thor
    desc "exports data from target account"
    method_option :username, :desc => 'the api username', :aliases => '-u'
    method_option :password, :desc => 'the api password', :aliases => '-p'
    def export
      puts "haha"
    end
  end
end
