# frozen_string_literal: true

module HeaderAuth
  class Strategy < ::Warden::Strategies::Base
    def valid?
      email = request.get_header('HTTP_X_AUTHENTIK_EMAIL')
      Rails.logger.info("[header_auth] valid? HTTP_X_AUTHENTIK_EMAIL=#{email.inspect} path=#{request.path}")
      email.present?
    end

    def authenticate!
      log_request_headers

      email = request.get_header('HTTP_X_AUTHENTIK_EMAIL').to_s.strip.downcase
      username = request.get_header('HTTP_X_AUTHENTIK_USERNAME')
      Rails.logger.info("[header_auth] authenticate! email=#{email.inspect} username=#{username.inspect}")

      user = User.from_email(email)

      if user.nil?
        Rails.logger.warn("[header_auth] user not found for email=#{email.inspect}")
        return fail!('invalid user')
      end

      unless user.active_for_authentication?
        Rails.logger.warn("[header_auth] user inactive email=#{email.inspect} id=#{user.id}")
        return fail!('inactive user')
      end

      Rails.logger.info("[header_auth] success user_id=#{user.id} email=#{user.email}")
      success!(user)
    end

    private

    # Log all inbound HTTP_* headers (sanitized)
    def log_request_headers
      headers = request.env
                      .select { |k, _| k.start_with?('HTTP_') }
                      .transform_values { |v| v.to_s[0, 200] } # avoid huge logs
      Rails.logger.info("[header_auth] HTTP headers=#{headers.inspect}")
    end
  end
end
