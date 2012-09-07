require 'nokogiri'

module Salesforce
  class Job
    attr_reader :options, :api, :job_info

    class << self
      def create api, opts={}, &block
        return new api, opts, &block
      end
    end

    def initialize api, opts={}, &block
      @options = { concurrency_mode: "Parallel", content_type: "CSV" }.merge(opts)

      verify_options

      @api = api
      @attributes = {}
      @batches = []
      @job_info = JobInfo.new options

       
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

    def id
      job_info.id unless job_info.nil?
    end

    def create
      xml = api.request :post do |req|
        req.body = job_info.create_job_xml
      end
      job_info.update_attributes Hash.from_xml(xml)["jobInfo"]
    end

    def batch data, content_type=nil
      xml = api.request :post, "/#{id}/batch" do |req|
        req.body = data
        req.headers["Content-Type"] = content_type || "text/csv; charset=UTF-8"
      end

      job_info.add_batch BatchInfo.new Hash.from_xml(xml)["batchInfo"]
    end

    def close
      xml = api.request :post, "/#{id}" do |req|
        req.body = job_info.close_job_xml
      end
      job_info.update_attributes Hash.from_xml(xml)["jobInfo"]
    end

    def get_status
      xml = api.request :get, "/#{id}"
      job_info.update_attributes Hash.from_xml(xml)["jobInfo"]
    end

    def all_batches_status
      xml = api.request :get, "/#{id}/batch"
      batch_info_result = Hash.from_xml(xml)["batchInfoList"]["batchInfo"]
      
      if batch_info_result.is_a? Array
        batch_info_result.each { |batch_info|
          job_info.find_batch(batch_info["id"]).update_attributes batch_info
        }
      else
        job_info.find_batch(batch_info["id"]).update_attributes batch_info
      end 
    end

    def get_batch_status batch_id
      xml = api.request :get, "/#{id}/batch/#{batch_id}"
      batch_info = Hash.from_xml(xml)["batchInfo"]
      job_info.find_batch(batch_info["id"]).update_attributes batch_info
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

      job_info.batches.each do |batch|
        results[batch.id] = batch_results(batch.id)
      end

      results
    end

    def state
      get_status
      job_info.state
    end

    def complete?
      get_status
      job_info.number_batches_completed.to_i == job_info.batches.size
    end

    def batch_complete? batch_id
      batch_status(batch_id).state == "Completed"
    end

    protected


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

