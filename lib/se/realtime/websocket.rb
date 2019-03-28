require "mechanize"
require "nokogiri"
require "websocket/driver"
require "json"
require "permessage_deflate"
require "open-uri"
require 'openssl'

module SE
  module Realtime
    class WSClient
      attr_reader :url, :thread, :driver
      attr_accessor :handler

      # If you're looking back it this, look at super_logger (ws_super_logger, panic switch logging) and logger (realtime, messages (and some warnings))

      def initialize(url, cookies, logs: false, &handler)
        @super_logger = Logger.new(logs ? 'ws_super_logger.log' : '/dev/null')

        @uri = URI.parse(url)
        @url = "ws#{@uri.scheme.split("")[4]}://#{@uri.host}"

        if @uri.scheme.split("")[4] == 's'
          @socket = TCPSocket.new(@uri.host, 443)
          @super_logger.info "Opened TCP socket for (port 443) #{@uri} (#{@socket})"
          @socket = OpenSSL::SSL::SSLSocket.new(@socket)
          @socket.connect
          @super_logger.info "Upgrade TCP socket to SSL socket socket for #{@uri} (#{@socket})"
        else
          @socket = TCPSocket.new(@uri.host, 80)
          @super_logger.info "Opened TCP socket for (port 80) #{@uri} (#{@socket})"
        end

        @handler = handler
        @logger = Logger.new(logs ? "realtime.log" : '/dev/null')
        @restart = true
        @super_logger.info "Set @restart to #{@restart}"

        @driver = WebSocket::Driver.client(self)
        @driver.add_extension PermessageDeflate
        @driver.set_header "Cookies", cookies if cookies
        @driver.set_header "Origin", "#{@uri.scheme}://#{@uri.host.split('.')[-2..-1].join('.')}"

        @driver.on :connect, ->(_e) {}

        @driver.on :open, ->(_e) do
          send "155-questions-active"
          @super_logger.info "Socket open. Subscribed to 155-questions-active"
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
          @super_logger.info "Socket was closed. @restart == #{@restart}"
          if @restart
            @logger.info "Attempting to reopen websocket..."
            @super_logger.info "Attempting to reopen socket"
            @driver.start
          end
        end

        @driver.on :error, ->(e) { @logger.error e }

        @driver.start

        @dead = false
        @thread = Thread.new do
          trap("SIGINT") do
            @restart = false
            @dead = true
            @super_logger.info "Got SIGINT. Dying."
            close
            Thread.exit
          end
          begin
            @driver.parse(@socket.is_a?(TCPSocket) ? @socket.recv(1) : @socket.sysread(1)) until @dead
          rescue IOError, SystemCallError => e
            @super_logger.warn "Got some kind of interrupt in the thread. Panic."
            @logger.warn "Recieved #{e} closing TCP socket. You shouldn't be worried :)"
          end
          @super_logger.warn "Left TCPSocket.recv loop. If you're reading this, panic."
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
        @super_logger.warn "Was told to close. Was sad."
        @dead = true
        @driver.close
        @socket.is_a?(TCPSocket) ? @socket.shutdown : @socket.sysclose
      rescue IOError, Errno::ENOTCONN => e
        @logger.error "Recieved #{e.class} trying to close websocket. Ignoring..."
      end
    end
  end
end
