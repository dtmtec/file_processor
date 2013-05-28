# FileProcessor

A more powerful CSV file processor

## Installation

Add this line to your application's Gemfile:

    gem 'file_processor'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install file_processor

## Usage

Use it as you would use Ruby's CSV:

    csv = FileProcessor::CSV.new(filename, options)
    csv.each do |row|
      # process row here
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
