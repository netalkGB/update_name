require 'bundler'
Bundler.require
class Auth
  attr_reader :authorize_url, :access_token, :access_token_secret
  def initialize (consumerkey,consumersecret)
    consumer = OAuth::Consumer.new consumerkey, consumersecret, site: 'https://api.twitter.com'
    @request_token = consumer.get_request_token
    @authorize_url = @request_token.authorize_url
  end

  def pin(pin)
    access_tokens = @request_token.get_access_token oauth_verifier: pin
    @access_token = access_tokens.token
    @access_token_secret = access_tokens.secret
  end
end