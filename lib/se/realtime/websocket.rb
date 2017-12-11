require "mechanize"
require "nokogiri"
require "websocket/driver"
require "json"
require "permessage_deflate"
require "open-uri"

module SE
  module Realtime
    class WSClient
      attr_reader :url, :thread, :driver
      attr_accessor :handler

      def initialize(url, cookies, &handler)
        @uri = URI.parse(url)
        @url = "ws#{@uri.scheme.split("")[4]}://#{@uri.host}"
        @driver = WebSocket::Driver.client(self)
        @socket = TCPSocket.new(@uri.host, 80)
        @handler = handler

        @driver.add_extension PermessageDeflate
        @driver.set_header "Cookies", cookies if cookies
        @driver.set_header "Origin", "#{@uri.scheme}://#{@uri.host.split('.')[-2..-1].join('.')}"
        
        @driver.on :connect, ->(_e) {}

        @driver.on :open, ->(_e) do
          send "155-questions-active"
          puts "WebSocket is open!"
        end

        @driver.on :message do |e|
          data = JSON.parse(e.data)
          if data["action"] == "hb"
            send "hb"
          else
            @handler.call(data)
          end
        end

        @driver.on :close, ->(_e) { puts "WebSocket is closed!"}

        @driver.on :error, ->(e) { STDERR.puts e }

        @driver.start

        @thread = Thread.new do
          trap("SIGINT") do
            close
            Thread.exit
          end
          loop do
            begin
              @driver.parse(@socket.recv(1))
            rescue IOError, SystemCallError => e
              puts "Recieved #{e} closing TCP socket. You shouldn't be worried :)"
            end
          end
        end

        at_exit { @thread.join }
      end

      def send(message)
        puts "BLURGLED" if message == "hb"
        @driver.text(message)
      end

      def write(data)
        @socket.write(data)
      end

      def close
        @driver.close
        @socket.shutdown
      rescue IOError, Errno::ENOTCONN => e
        STDERR.puts "Recieved #{e.class} trying to close websocket. Ignoring..."
      end
    end
  end
end
