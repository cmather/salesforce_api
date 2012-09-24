require 'oauth2'
require 'multi_json'

module Salesforce
  class Api
    attr_reader :options
    class_attribute :options
    self.options = {
      authorize_url: "https://login.salesforce.com",
      authorize_path: "/services/oauth2/authorize",
      authorize_token_path: "/services/oauth2/token"
    }

    def initialize opts={}
      @options = opts.merge self.class.options.dup
      verify_options
    end

    def verify_options
      raise "Missing 'client_key' option" unless options[:client_key] || ENV["salesforce_key"] 
      raise "Missing 'client_secret' option" unless options[:client_secret] || ENV["salesforce_secret"] 
    end

    def api_url
      options[:instance_url]
    end

    def api_path
      raise NotImplementedError 
    end

    def instance_url
      options[:instance_url]
    end

    def instance_url?
      !!options[:instance_url]
    end

    def access_token
      options[:token]
    end

    def access_token?
      !!options[:token] 
    end

    def client_key
      options[:client_key] || ENV["salesforce_key"] 
    end

    def client_secret
     options[:client_secret] ||ENV["salesforce_secret"] 
    end

    def oauth_token
      @oauth_token ||= begin
        ::OAuth2::AccessToken.from_hash auth_client, options.slice(:token, :refresh_token)
      end
    end

    def get_oauth_token opts={}
      strategy = opts[:strategy] || auth_strategy
      args = auth_args_for strategy, opts
      token = auth_client.send(strategy).get_token *args
      options[:instance_url] = token.params["instance_url"]
      options[:id_url] = token.params["id"]
      options[:token] = token.token
      options[:refresh_token] = token.refresh_token
      token.client.site = options[:instance_url]
      @oauth_token = token
    end

    def auth_strategy
      if options[:username] && options[:password]
        return :password
      else
        return :auth_code
      end  
    end

    def auth_args_for strategy, opts={}
      case strategy
      when :password
        unless options[:username] && options[:password]
          raise "You're authenticating with the password strategy but you didn't initialize the SFApi::Client with a username and password"
        end
        [options[:username], options[:password]]
      when :auth_code
        [opts[:code]]
      else
        raise "You didn't specify an authentication strategy"
      end
    end

    def auth_options
      {
        site: options[:authorize_url],
        token_url: options[:authorize_token_path],
        authorize_url: options[:authorize_path],
        token: options[:token],
        refresh_token: options[:refresh_token]
      }
    end

    def auth_client
      ::OAuth2::Client.new client_key, client_secret, auth_options
    end

    def request verb, path, opts={}, &block
      raise NotImplementedError
    end

    def headers
      {} 
    end

    def api_connection
      Faraday.new url: api_url, headers: headers
    end
  end
end
