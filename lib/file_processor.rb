require "file_processor/version"
require "delegate"
require "csv"
require "zlib"
require "open-uri"
require "tempfile"

module FileProcessor
end

require "file_processor/temp_file"
require "file_processor/csv"

### API 1
# FileProcessor::CSV.open(filename, options) do |csv|
#   csv.count # 527
#   csv.encoding # utf-8
#   csv.sample_data(4) # returns the first 4 rows, as an array of arrays
#   csv.col_sep
#   csv.headers
#
#   csv.each_with_index do |row|
#     # process
#   end
#
# end # close csv
#
# ### API 2
# csv = FileProcessor::CSV.new(filename, options)
# csv.count # 527
#
# csv.each_with_index do |row, index|
#   # process
# end
# csv.close
#
