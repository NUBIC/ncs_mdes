#!/usr/bin/env ruby

##
# A script which scans an MDES spreadsheet for indications that an instrument
# table's p_id is for a child (vs. for a parent.)
#
# This script requires the 'roo' gem, which is not included in
# ncs_mdes's gemspec because it has a huge number of dependencies and
# is not needed at runtime.

require 'roo'
require 'yaml'

MDES_XLSX = ARGV.first or fail 'Please provide the path to the MDES spreadsheet'
SHEET_NAME = 'Data Elements'

COLUMNS = {
  'A' => :table_type,
  'B' => :table_label,
  'C' => :table_name,
  'D' => :variable_name,
  'I' => :variable_def
}

book = Excelx.new(MDES_XLSX)

3.upto(book.last_row(SHEET_NAME)) do |row_number|
  row = COLUMNS.keys.each_with_object({}) { |col, i| i[COLUMNS[col]] = book.cell(row_number, col, SHEET_NAME) }
  next unless row[:table_type] =~ /instrument/i
  next unless row[:variable_name] =~ /\Ap_id\Z/i

  puts "#{row[:table_name].downcase}.#{row[:variable_name].downcase}"
  if row[:variable_def] =~ /child/i
    puts "- mentions child in variable def"
  end
  if row[:table_label] =~ /child/i
    puts "- mentions child in table label"
  end
end
