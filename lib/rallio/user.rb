module Rallio
  class User < Base
    attribute :id, Integer
    attribute :email, String
    attribute :first_name, String
    attribute :last_name, String
    attribute :accounts, Array[Account]
    attribute :franchisors, Array[Franchisor]

    def self.accessible_users
      response = self.get('/accessible_users', headers: app_credentials)
      response.parsed_response[:users].map { |u| User.new(u) }
    end

    def sign_on_tokens
      response = self.class.post("/users/#{id}/sign_on_tokens", headers: app_credentials)
      SignOnToken.new response.parsed_response[:sign_on_token]
    end

    def access_token
      @access_token ||= AccessToken.create(user_id: id)
    end
  end
end
