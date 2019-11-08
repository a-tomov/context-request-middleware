# frozen_string_literal: true

module ContextRequestMiddleware
  module Context
    HTTP_COOKIE       = 'HTTP_COOKIE'.freeze

    # Class for retrieving the session if set via rack cookie.
    # This requires the session and more data to be stored in
    # '_session_id' cookie key.
    class CookieSessionRetriever
      include ActiveSupport::Configurable

      HTTP_HEADER = 'Set-Cookie'

      attr_accessor :data

      def initialize(request)
        @request = request
        @data = {}
      end

      def call(status, header, body)
        @response = Rack::Response.new(body, status, header)
        if new_session_id?
          data[:context_id] = session_id
          data[:owner_id] = owner_id
          data[:context_status] = context_status
          data[:context_type] = context_type
          data[:app_id] = ContextRequestMiddleware.app_id
        end
        data
      end

      # returns if current request sets a new session id - used to send a context message
      def new_session_id?
        setting_session_id_now && setting_session_id_now != req_cookie_session_id
      end
      private

      def owner_id
        from_env('cookie_session.user_uuid', 'unknown')
      end

      def context_status
        'unknown'
      end

      def context_type
        'session_cookie'
      end

      # returns the new session_id if its being set now
      def setting_session_id_now
        new_session = nil
        new_session = set_cookie_header.match(/_session_id=([^\;]+)/) if set_cookie_header
        @session_id = new_session[1] if new_session
      end

      def session_id
        # check for a new session id
        setting_session_id_now
        # if NO new session id - get the current session id
        @session_id ||= req_cookie_session_id
      end

      def req_cookie_session_id
        parse_cookies(@request.env)['_session_id'] ||
          (@request.env['action_dispatch.cookies'] || {})['_session_id']
      end

        def set_cookie_header
        @response.headers.fetch(HTTP_HEADER, nil)
      end

      def from_env(key, default = nil)
        # ENV[key] || default
        ENV.fetch(key, default)
        # TODO need to debug why the below line doesn't work
        # @request.env.fetch(key, default)
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
