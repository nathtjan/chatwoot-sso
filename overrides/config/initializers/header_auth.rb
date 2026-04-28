# frozen_string_literal: true

# This is only for development/testing to confirm the
# initializer is loaded and the middleware is running.
STDOUT.puts "[header_auth] initializer loaded (STDOUT)"

require Rails.root.join('lib/header_auth/strategy')
require Rails.root.join('lib/header_auth/middleware')

Warden::Strategies.add(:header_auth, HeaderAuth::Strategy)

Devise.setup do |config|
  config.warden do |manager|
    manager.default_strategies(scope: :user).unshift :header_auth
  end
end

Rails.application.config.middleware.insert_after Warden::Manager, HeaderAuth::Middleware
