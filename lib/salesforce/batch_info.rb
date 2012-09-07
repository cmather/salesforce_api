module Salesforce
  class BatchInfo < Resource
    attr_accessor :apex_processing_time
    attr_accessor :api_active_processing_time
    attr_accessor :created_date
    attr_accessor :id
    attr_accessor :job_id
    attr_accessor :number_records_failed
    attr_accessor :number_records_processed
    attr_accessor :state
    attr_accessor :state_message
    attr_accessor :system_modstamp
    attr_accessor :total_processing_time
  end
end
