require 'nokogiri'

module Salesforce
  class JobInfo < Resource
    attr_accessor :api_version
    attr_accessor :apex_processing_time
    attr_accessor :api_active_processing_time
    attr_accessor :assignment_rule_id
    attr_accessor :concurrency_mode
    attr_accessor :content_type
    attr_accessor :created_by_id
    attr_accessor :created_date
    attr_accessor :external_id_field_name
    attr_accessor :id
    attr_accessor :number_batches_completed
    attr_accessor :number_batches_queued
    attr_accessor :number_batches_failed
    attr_accessor :number_batches_in_progress
    attr_accessor :number_batches_total
    attr_accessor :number_records_failed
    attr_accessor :number_records_processed
    attr_accessor :number_retries
    attr_accessor :object
    attr_accessor :operation
    attr_accessor :state
    attr_accessor :system_modstamp
    attr_accessor :total_processing_time

    attr_reader :batches

    class << self
    end

    def initialize attrs={}
      @batches = []
      super 
    end

    def add_batch batch
      batches << batch 
    end

    def find_batch id
      batches.select { |batch| batch.id == id }.first 
    end

    def xmlns
      "http://www.force.com/2009/06/asyncapi/dataload"
    end
    
    def create_job_xml
      Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
       xml.jobInfo(xmlns: xmlns) {
         xml.operation operation
         xml.object object
         xml.concurrencyMode concurrency_mode
         xml.contentType content_type
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
