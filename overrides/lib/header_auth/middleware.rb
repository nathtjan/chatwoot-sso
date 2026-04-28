# frozen_string_literal: true

require 'json'
require 'time'

module HeaderAuth
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      # Only try if header exists
      header_email = env['HTTP_X_AUTHENTIK_EMAIL']
      if header_email.present? && env['warden']
        Rails.logger.debug("[header_auth] middleware sees HTTP_X_AUTHENTIK_EMAIL=#{header_email.inspect}")
        env['warden'].authenticate(:header_auth)
      end

      status, headers, body = @app.call(env)

      # If Warden authenticated a user, mint DeviseTokenAuth token + cookie
      if header_email.present? && env['warden'] && (user = env['warden'].user(:user))
        # Avoid re-issuing if cookie already exists
        unless cookie_present?(headers)
          token_headers = user.create_new_auth_token
          set_auth_cookie!(headers, token_headers)
          Rails.logger.debug("[header_auth] issued cw_d_session_info for user_id=#{user.id}")
        end
      end

      [status, headers, body]
    end

    private

    def cookie_present?(headers)
      set_cookie = headers['Set-Cookie'].to_s
      set_cookie.include?('cw_d_session_info=')
    end

    def set_auth_cookie!(headers, token_headers)
      expiry = token_headers['expiry'].to_i
      expires_at = Time.at(expiry)

      cookie_value = JSON.generate(token_headers)
      cookie = "cw_d_session_info=#{Rack::Utils.escape(cookie_value)}; " \
               "path=/; expires=#{expires_at.httpdate}; SameSite=Lax"

      # Merge with existing cookies if any
      if headers['Set-Cookie'].present?
        headers['Set-Cookie'] = Array(headers['Set-Cookie']) << cookie
      else
        headers['Set-Cookie'] = cookie
      end
    end
  end
end
