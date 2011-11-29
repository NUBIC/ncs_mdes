require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'

RSpec::Core::RakeTask.new do |t|
  t.pattern = "spec/**/*_spec.rb"
end

namespace :ci do
  ENV["CI_REPORTS"] = "reports/spec-xml"

  desc "Run specs for CI"
  task :spec => ['ci:setup:rspec', 'rake:spec']
end

task :library do
  $LOAD_PATH << File.expand_path('../lib', __FILE__)
  require 'ncs_navigator/mdes'
end

desc 'Generate a dot-formatted graph of the FK relationships in an MDE spec'
task :fk_dot => :library do
  fail 'Please specify the MDES version with MDES="X.Y"' unless ENV['MDES']
  spec = NcsNavigator::Mdes(ENV['MDES'])

  filename = "foreign_keys-MDES_#{spec.specification_version}.dot"
  $stdout.write "Writing DOT graph to #{filename}..."

  File.open(filename, 'w') do |f|
    f.puts "digraph mdes_fks {"
    spec.transmission_tables.each do |t1|
      shape = if t1.primary_instrument_table?
                'diamond'
              elsif t1.instrument_table?
                'rect'
              else
                'oval'
              end
      f.puts "  #{t1.name} [shape=#{shape}];"
      t1.variables.collect(&:table_reference).compact.each do |t2|
        f.puts "  #{t1.name} -> #{t2.name};"
      end
    end
    f.puts "}"
  end
  $stdout.puts "done."
end
