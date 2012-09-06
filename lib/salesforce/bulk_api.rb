module Salesforce
  class BulkApi < Api
    def api_url
      return nil unless options[:instance_url]
      re = /(http|https)\:\/\/(.+)\.salesforce\.com/
      instance = re.match(options[:instance_url]).to_a.last
      "https://#{instance}-api.salesforce.com"
    end

    def api_path
      "/services/async/25.0/job" 
    end

    def create_job opts={}, &block
      Job.create self, opts, &block
    end

    def headers
      {
        "Content-Type" => "application/xml; charset=UTF-8",
        "X-SFDC-Session" => options[:access_token]
      }
    end

    def request verb, path="", opts={}, &block
      path = api_path + path
      response = api_connection.send verb, path, opts, &block
      response.body
    rescue Faraday::Error => e
      raise e
    end
  end
end
