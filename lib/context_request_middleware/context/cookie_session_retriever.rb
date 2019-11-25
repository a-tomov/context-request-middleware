# frozen_string_literal: true

module ContextRequestMiddleware
  module Context
    # Class for retrieving the session if set via rack cookie.
    # This requires the session and more data to be stored in
    # '_session_id' cookie key.
    class CookieSessionRetriever
      include ActiveSupport::Configurable
      include ContextRequestMiddleware::Cookie

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
        setting_session_id_now && setting_session_id_now != request_cookie_session_id
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
        @session_id ||= request_cookie_session_id
      end

      def request_cookie_session_id
        cookie_session_id(@request)
      end

      def set_cookie_header
        @response.headers.fetch(HTTP_HEADER, nil)
      end

      def from_env(key, default = nil)
        # @request.env.fetch(key, default)
        ENV.fetch(key, default)
      end
    end
  end
end
