#!/usr/bin/env ruby

##
# A script to generate disposition_codes.yml from the MDES 3.2
# spreadsheet's Dispositions tab.
#
# This script requires the 'roo' gem, which is not included in
# ncs_mdes's gemspec because it has a huge number of dependencies and
# is not needed at runtime.

require 'rubygems'
require 'roo'
require 'yaml'

MDES_XLSX = ARGV.first or fail 'Please provide the path to the MDES spreadsheet'
TARGET = File.expand_path('../disposition_codes.yml', __FILE__)
SHEET_NAME = 'Dispositions'

MAPPED_COLUMNS = {
  'A' => 'final_category',
  'B' => 'sub_category',
  'C' => 'disposition'
}

def normalize_whitespace(s)
  s.strip.gsub(/\s+/, " ")
end

book = Excelx.new(MDES_XLSX)

# This is the array of hashes that will eventually be serialized to
# disposition_codes.yml.
dispositions = []

current_event = nil
current_category_code = nil
1.upto(book.last_row(SHEET_NAME)) do |row_number|
  a, b = %w(A B).collect { |col| book.cell(row_number, col, SHEET_NAME) }
  if a =~ /Category\s+(\d)\s+\((.*?)\)\s+Disposition\s+Codes/
    current_event = normalize_whitespace $2
    current_category_code = $1.to_i
    puts "Collecting for category #{current_event} (#{current_category_code})"
  elsif b =~ /\S/ && a !~ /FINAL/
    disposition_hash = MAPPED_COLUMNS.inject({}) do |h, (col, key)|
      h[key] = normalize_whitespace(book.cell(row_number, col, SHEET_NAME)); h
    end
    disposition_hash['event'] = current_event
    disposition_hash['category_code'] = current_category_code
    disposition_hash['interim_code'], disposition_hash['final_code'] =
      normalize_whitespace(book.cell(row_number, 'D', SHEET_NAME)).split('/')

    dispositions << disposition_hash
  end
end

File.open(TARGET, 'w') do |f|
  f.write dispositions.sort_by { |h| [h['category_code'], h['final_code']] }.to_yaml
end
