require 'rspec'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ncs_navigator/mdes'

RSpec.configure do |config|
  config.before(:all) do
    v = NcsNavigator::Mdes::SourceDocuments::BASE_ENV_VAR
    @original_base, ENV[v] = ENV[v], File.expand_path('../doc-base', __FILE__)
  end

  config.after(:all) do
    ENV[NcsNavigator::Mdes::SourceDocuments::BASE_ENV_VAR] = @original_base
  end
end
