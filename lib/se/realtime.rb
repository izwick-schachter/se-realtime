require "se/realtime/version"
require "se/realtime/websocket"

module SE
  module Realtime
    class << self
      def on_post(&handler)
        ws do |e|
          data = JSON.parse e['data']
          handler.call(data)
        end
      end

      def json(site: nil, &handler)
        ws do |e|
          e['data'] = clean_keys(JSON.parse(e['data']))
          handler.call(e) if e[:site] == site || site.nil?
        end
      end

      def batch(size, **opts, &handler)
        posts = []
        json(**opts) do |e|
          posts << e
          if posts.length >= size
            handler(posts)
            posts = []
          end
        end
      end

      def ws(&block)
        WSClient.new("https://qa.sockets.stackexchange.com", cookies, &block)
      end

      private

      def clean_keys(json)
        {
          'apiSiteParameter' => :site,
          'titleEncodedFancy' => :title,
          'bodySummary' => :body,
          'lastActivityDate' => :last_active,
          'siteBaseHostAddress' => :site_url
        }.each do |old_key, new_key|
          json[new_key] = json.delete(old_key) if json.key?(old_key)
        end
        json.map do |k,v|
          if k.is_a? String
            [k.gsub(/([a-z\d])([A-Z])/,'\1_\2').downcase.to_sym,v]
          else
            [k.to_sym,v]
          end
        end.to_h
      end

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
