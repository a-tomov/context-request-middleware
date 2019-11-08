# frozen_string_literal: true

module ContextRequestMiddleware
  module Request
    HTTP_COOKIE       = 'HTTP_COOKIE'.freeze

    # Class for retrieving the session if set via rack cookie.
    # This requires the session id to be stored in '_session_id'
    # cookie key.
    class CookieSessionIdRetriever
      include ActiveSupport::Configurable

      def initialize(request)
        @request = request
      end

      def call
        parse_cookies(@request.env)['_session_id'] ||
          (@request.env['action_dispatch.cookies'] || {})['_session_id']
      end

      def parse_cookies(env)
        parse_cookies_header env[HTTP_COOKIE]
      end

      def parse_cookies_header(header)
        # According to RFC 2109:
        #   If multiple cookies satisfy the criteria above, they are ordered in
        #   the Cookie header such that those with more specific Path attributes
        #   precede those with less specific.  Ordering with respect to other
        #   attributes (e.g., Domain) is unspecified.
        cookies = Rack::Utils.parse_query(header, ';,') { |s| unescape(s) rescue s }
        cookies.each_with_object({}) { |(k,v), hash| hash[k] = Array === v ? v.first : v }
      end
    end
  end
end
