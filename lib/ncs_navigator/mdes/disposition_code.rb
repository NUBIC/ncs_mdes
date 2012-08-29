require 'ncs_navigator/mdes'

module NcsNavigator::Mdes
  ##
  # One dispostion code in the MDES.
  class DispositionCode

    attr_accessor :event
    attr_accessor :final_category
    attr_accessor :sub_category
    attr_accessor :disposition
    attr_accessor :interim_code
    attr_accessor :final_code

    ##
    # Given attributes (presumably loaded from a YAML file) create
    # a new instance of a DispositionCode
    # 
    # @return [DispositionCode] the created instance.
    def initialize(attrs)
      [:event, :final_category, :sub_category, :disposition, :interim_code, :final_code].each do |a|
        self.send("#{a}=", attrs[a.to_s])
      end
    end

    ##
    # If the code's final category signifies successful completion, returns
    # true; otherwise, returns false.
    #
    # @return [Boolean]
    def success?
      final_category.to_s.start_with?('Complete')
    end

    ##
    # Provides a briefer inspection for cleaner IRB use.
    #
    # @return [String]
    def inspect
      "\#<#{self.class} event=#{event.inspect} disposition=#{disposition.inspect} status_code=#{interim_code.inspect}/#{final_code.inspect}>"
    end
  end
end
