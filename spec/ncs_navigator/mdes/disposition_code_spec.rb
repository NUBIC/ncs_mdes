require File.expand_path('../../../spec_helper', __FILE__)

module NcsNavigator::Mdes
  describe DispositionCode do
    let(:code) { DispositionCode.new({}) }

    describe '#success?' do
      describe 'if #final_category starts with "Complete"' do
        before do
          code.final_category = 'Complete Interview'
        end

        it 'returns true' do
          code.should be_success
        end
      end

      describe 'if #final_category does not start with "Complete"' do
        before do
          code.final_category = 'Eligible Non-Interview'
        end

        it 'returns false' do
          code.should_not be_success
        end
      end

      describe 'if #final_category is nil' do
        before do
          code.final_category = nil
        end

        it 'returns false' do
          code.should_not be_success
        end
      end
    end
  end
end
