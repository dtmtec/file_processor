# FileProcessor

[![build status][1]][2]
[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/dtmtec/file_processor/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

[1]: https://travis-ci.org/dtmtec/file_processor.png
[2]: http://travis-ci.org/dtmtec/file_processor

A more powerful CSV file processor

## Installation

FileProcessor uses the new CSV library introduced in Ruby 1.9.3, thus it is only compatible with this Ruby version.

Add this line to your application's Gemfile:

    gem 'file_processor'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install file_processor

## Usage

Use it as you would use Ruby's CSV:

    FileProcessor::CSV.open(filename, options) do |csv|
      csv.each do |row|
        # process row here
      end
    end # automatically closes the file

FileProcessor::CSV is just a wrapper around Ruby's CSV, so you can manipulate it as you would manipulate Ruby's CSV.

You can also use `FileProcessor::CSV#process_range` to process a range in the file:

    FileProcessor::CSV.open(filename, options) do |csv|
      csv.process_range(offset: 2000, limit: 1000) do |row, index|
        # yields 1000 rows starting from line 2000 (i.e., from line 2000 to line 2999)
      end
    end # automatically closes the file

Here are the added features:

* Auto-detect encoding of UTF-8 and ISO-8859-1 (Latin1) files.
* Auto-detect the column separator (`col_sep` option) when not given.
* Skip lines without data when `skip_blank` is `true`, which is turned on by default. This means that count will not take these lines into account. Also skips them when iterating through lines.
* Detects if a file is gzipped, and decompress it for you automatically.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
