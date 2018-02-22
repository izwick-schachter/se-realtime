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
        @socket = TCPSocket.new(@uri.host, @uri.scheme.split("")[4] == 's' ? 443 : 80)
        @handler = handler
        @logger = Logger.new "realtime.log"
        @restart = true

        @driver.add_extension PermessageDeflate
        @driver.set_header "Cookies", cookies if cookies
        @driver.set_header "Origin", "#{@uri.scheme}://#{@uri.host.split('.')[-2..-1].join('.')}"
        
        @driver.on :connect, ->(_e) {}

        @driver.on :open, ->(_e) do
          send "155-questions-active"
          @logger.info "WebSocket is open!"
        end

        @driver.on :message do |e|
          @logger.info("Read:  #{e.data}")
          data = JSON.parse(e.data)
          if data["action"] == "hb"
            send "hb"
          else
            @handler.call(data)
          end
        end

        @driver.on :close, ->(_e) do
          @logger.info "Realtime WebSocket is closing."
          if @restart
            @logger.info "Attempting to reopen websocket..."
            @driver.start
          end
        end

        @driver.on :error, ->(e) { @logger.error e }

        @driver.start

        @thread = Thread.new do
          trap("SIGINT") do
            @restart = false
            close
            Thread.exit
          end
          loop do
            begin
              @driver.parse(@socket.recv(1))
            rescue IOError, SystemCallError => e
              @logger.warn "Recieved #{e} closing TCP socket. You shouldn't be worried :)"
            end
          end
        end

        at_exit { @thread.join }
      end

      def send(message)
        @logger.info "Lub dub" if message == "hb"
        @logger.info("Wrote: #{message}")
        @driver.text(message)
      end

      def write(data)
        @socket.write(data)
      end

      def close
        @driver.close
        @socket.shutdown
      rescue IOError, Errno::ENOTCONN => e
        @logger.error "Recieved #{e.class} trying to close websocket. Ignoring..."
      end
    end
  end
end
