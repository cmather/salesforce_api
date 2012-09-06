module Salesforce
  class DataApi < Api

    def api_path
      "/services/data/v25.0"
    end

    def query soql
      request :get, "/query" do |req|
        req.params['q'] = soql
      end 
    end

    def request verb, path="", opts={}, &block
      path = api_path + path
      token = oauth_token
      token.client.site = api_url
      response = token.request verb, path, opts, &block
      response.body
    end
  end
end

