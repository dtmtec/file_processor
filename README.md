# FileProcessor

[![Build Status](https://travis-ci.org/dtmconsultoria/file_processor.png)](https://travis-ci.org/dtmconsultoria/file_processor)

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
