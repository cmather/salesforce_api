module Salesforce
  class Resource

    def initialize attrs={}
      update_attributes attrs
    end

    def update_attributes attrs={}
      attrs.each do |k,v|
        attr = "#{k}=".underscore
        if respond_to? attr
          send attr, v
        end
      end 
      self
    end
  end
end
