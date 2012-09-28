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

    def objects
      request :get, "/sobjects"
    end

    def describe_object object_name
      request :get, "/sobjects/#{object_name.capitalize}/describe"
    end

    def object_row_template object_name, id
      request :get, "/sobjects/#{object_name.capitalize}/#{id}" 
    end

    def request verb, path="", opts={}, &block
      path = api_path + path
      token = oauth_token
      token.client.site = api_url
      response = token.request verb, path, opts, &block
      JSON.parse response.body
    end

    def get url
      oauth_token.client.site = url
      response = oauth_token.get 
      JSON.parse response.body
    end
  end
end

