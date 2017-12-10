require "se/realtime/version"
require "se/realtime/websocket"

module SE
  module Realtime
    class << self
      def on_post(&handler)
        WSClient.new("https://qa.sockets.stackexchange.com", cookies) do |e|
          data = JSON.parse e['data']
          handler.call(data)
        end
      end

      private

      def cookies
        agent = Mechanize.new
        agent.get("https://stackexchange.com/questions?realtime")
        cookie_array = agent.cookies.map do |cookie|
          "#{cookie.name}=#{cookie.value}" if cookie.domain.end_with? "stackexchange.com"
        end
        (cookie_array - [nil]).join("; ")
      end
    end
  end
end
