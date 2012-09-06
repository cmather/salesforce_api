require 'nokogiri'

module Salesforce
  class Job
    attr_reader :id, :options, :api, :attributes, :batches

    class << self
      def create api, opts={}, &block
        return new api, opts, &block
      end
    end

    def initialize api, opts={}, &block
      @api = api
      @options = { concurrency_mode: "Parallel", content_type: "CSV" }.merge(opts)
      @attributes = {}
      @batches = []
      
      verify_options
       
      if block_given?
        create
        instance_eval &block
        close
      end
    end

    def verify_options
      raise "Missing 'object' option" unless options.has_key? :object
      raise "Missing 'operation' option" unless options.has_key? :operation 
      true
    end

    def create
      xml = api.request :post do |req|
        req.body = create_job_xml
      end
      job_info = Hash.from_xml(xml)["jobInfo"]
      @attributes = {}
      job_info.each do |key, value|
        attributes[key] = value
      end
      @id = attributes["id"]
      attributes
    end

    def add_batch data, content_type=nil
      xml = api.request :post, "/#{id}/batch" do |req|
        req.body = data
        req.headers["Content-Type"] = content_type || "text/csv; charset=UTF-8"
      end
      batch_info = Hash.from_xml(xml)["batchInfo"]
      @batches << batch_info
      batch_info 
    end

    def close
      xml = api.request :post, "/#{id}" do |req|
        req.body = close_job_xml
      end

      job_info = Hash.from_xml(xml)["jobInfo"]
      @attributes = {}

      unless job_info
        puts xml
        raise "job_info is nil"
      end
      
      job_info.each do |key, value|
        attributes[key] = value
      end

      job_info
    end

    def status
      xml = api.request :get, "/#{id}"
      batch_info = Hash.from_xml(xml)["jobInfo"]
      batch_info
    end

    def all_batches_status
      xml = api.request :get, "/#{id}/batch"
      batch_info = Hash.from_xml(xml)["batchInfoList"]["batchInfo"]
      batch_info.is_a?(Array) ? batch_info : [batch_info]
    end

    def batch_status batch_id
      xml = api.request :get, "/#{id}/batch/#{batch_id}"
      batch_info = Hash.from_xml(xml)["batchInfo"]
      batch_info
    end

    def batch_results batch_id=nil
      results = []
      xml = api.request :get, "/#{id}/batch/#{batch_id}/result"
      result_list = Hash.from_xml(xml)["result_list"]["result"]
      result_list = result_list.is_a?(Array) ? result_list : [result_list]
      result_list.each do |key|
        result = api.request :get, "/#{id}/batch/#{batch_id}/result/#{key}"
        results << result
      end 

      results
    end

    def results

      return false unless complete?

      results = {}

      batches.each do |batch|
        batch_id = batch["id"]
        results[batch_id] = batch_results(batch_id)
      end

      results
    end

    def state
      status["state"]
    end

    def complete?
      status["numberBatchesCompleted"].to_i == batches.size
    end

    def batch_complete? batch_id
      batch_status(batch_id)["state"] == "Completed"
    end

    protected

    def xmlns
      "http://www.force.com/2009/06/asyncapi/dataload"
    end

    def create_job_xml
      Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
         xml.jobInfo(xmlns: xmlns) {
           xml.operation options[:operation]
           xml.object options[:object]
           xml.concurrencyMode options[:concurrency_mode]
           xml.contentType options[:content_type]
         }
      end.to_xml 
    end

    def close_job_xml
      Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
         xml.jobInfo(xmlns: xmlns) {
           xml.state "Closed"
         }
      end.to_xml 
    end
  end
end

