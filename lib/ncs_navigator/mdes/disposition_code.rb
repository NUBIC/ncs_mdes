require 'ncs_navigator/mdes'

module NcsNavigator::Mdes
  ##
  # One dispostion code in the MDES.
  class DispositionCode
    ATTRIBUTES = %w(
      category_code disposition event final_category final_code interim_code sub_category
    )

    ATTRIBUTES.each do |attr|
      attr_accessor attr
    end

    ##
    # Given attributes (presumably loaded from a YAML file) create
    # a new instance of a DispositionCode
    # 
    # @return [DispositionCode] the created instance.
    def initialize(attrs)
      ATTRIBUTES.each { |a| send("#{a}=", attrs[a]) }
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
