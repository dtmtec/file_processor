module FileProcessor
  class CSV < SimpleDelegator
    include Enumerable

    # Opens a file and yields it, ensuring that it is properly closed.
    def self.open(*args)
      instance = new(*args)

      if block_given?
        begin
          yield instance
        ensure
          instance.close if instance
        end
      else
        instance
      end
    end

    attr_accessor :detected_encoding

    def initialize(filename, options={})
      @gzipped      = options.delete(:gzipped)

      load(filename, options.delete(:open_options))

      @options      = default_options.merge(options)

      @options[:encoding] ||= detect_encoding
      @detected_encoding  ||= Encoding.find(@options[:encoding])

      tempfile.reopen(detected_mode) if tempfile.closed?

      @options[:col_sep]  ||= detect_column_separator

      super(::CSV.new(tempfile, @options))
    end

    # Counts the number of rows in the file, even if it has already been read
    #
    # @return [ Integer ] the number of rows in the file
    def total_count(&block)
      rewind
      count(&block)
    ensure
      rewind
    end

    #
    # Yields each row of the data source in turn, skipping blanks and rows with no data.
    #
    # Support for Enumerable.
    #
    # The data source must be open for reading.
    #
    def each
      if block_given?
        while row = shift
          yield row unless skip_blanks? && row_with_no_data?(row)
        end
      else
        to_enum
      end
    end

    # Process a range of lines in the CSV file.
    #
    # @example Process 1000 lines starting from the line 2000
    #   csv.process_range(offset: 2000, limit: 1000) do |row, index|
    #     # process range here
    #   end
    #
    # @param [ Hash ] options A hash with offset and/or limit
    #
    # @option options [ Integer ] :offset The offset from which the process should start
    # @option options [ Integer ] :limit  The number of rows to process
    #
    # @return [ Enumerable ] CSV's enumerable
    def process_range(options={})
      options ||= {}

      offset = options[:offset] || 0
      limit  = options[:limit]  || -1

      rewind
      each_with_index do |row, index|
        next if index < offset
        break if limit >= 0 && index >= offset + limit

        yield row, index
      end
    ensure
      rewind
    end

    # Returns true when the file is gzipped, false otherwise
    def gzipped?
      @gzipped
    end

    private

    def detect_compression?
      @gzipped.nil?
    end

    def row_with_no_data?(row)
      row = row.fields if row.respond_to?(:fields)
      row.all? { |column| column.nil? || column.empty? }
    end

    def load(filename, open_options)
      loaded_io = decompress(::Kernel.open(filename, 'rb', open_options || {}))
      loaded_io.rewind

      @original_default_internal = Encoding.default_internal
      Encoding.default_internal = nil

      loaded_io.each do |line|
        tempfile.write(line)
      end
    ensure
      tempfile.close
      loaded_io.close
      Encoding.default_internal = @original_default_internal
    end

    def decompress(loaded_io)
      if detect_compression? || gzipped?
        Zlib::GzipReader.open(loaded_io).tap do |decompressed_io|
          decompressed_io.getc # attempt to read from a compressed io
          @gzipped = true
        end
      else
        @gzipped = false
        loaded_io
      end
    rescue Zlib::Error
      # not a compressed io, just returning the loaded io instead
      @gzipped = false
      loaded_io
    end

    # We open the file and try to read each line of it, if there is an
    # invalid byte sequence, an ArgumentError exception will be thrown.
    #
    # We then assume that the file is in ISO-8859-1 encoding, and transcode
    # it to UTF-8. Though its ugly, this was the only way to detect whether
    # a file was using one of these encodings.
    def detect_encoding
      tempfile.reopen('r:utf-8')
      tempfile.each(&:split) # raises ArgumentError when it has non-ascii characters that are not in UTF-8

      @detected_encoding = Encoding.find('utf-8')
    rescue ArgumentError
      tempfile.reopen('r:iso-8859-1:utf-8')
      @detected_encoding = Encoding.find('iso-8859-1')
    ensure
      tempfile.rewind
    end

    def detected_utf_8?
      detected_encoding == Encoding.find('utf-8')
    end

    def detected_mode
      detected_utf_8? ? 'r:utf-8' : 'r:iso-8859-1:utf-8'
    end

    def detect_column_separator
      @col_sep = tempfile.gets.split(';').size > 1 ? ';' : ','
    ensure
      tempfile.rewind
    end

    def default_options
      {
        skip_blanks: true
      }
    end

    def tempfile
      @tempfile ||= FileProcessor::Tempfile.new
    end
  end
end