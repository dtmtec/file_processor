module FileProcessor
  class CSV < SimpleDelegator
    def initialize(filename, options={})
      @gzipped      = options.delete(:gzipped)

      load(filename, options.delete(:open_options))

      @options      = default_options.merge(options)

      @options[:encoding] ||= detect_encoding
      @options[:col_sep]  ||= detect_column_separator

      super(::CSV.new(tempfile, @options))
    end

    def count
      rewind
      super do |row|
        !skip_blanks? || row.any? { |column| !column.nil? && !column.empty? }
      end
    ensure
      rewind
    end

    def gzipped?
      @gzipped
    end

    private

    def detect_compression?
      @gzipped.nil?
    end

    def load(filename, open_options)
      loaded_io = decompress(::Kernel.open(filename, 'rb', open_options || {}))
      loaded_io.rewind

      loaded_io.each do |line|
        tempfile.write(line)
      end
    ensure
      tempfile.close
      loaded_io.close
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

      Encoding.find('utf-8')
    rescue ArgumentError
      tempfile.reopen('r:iso-8859-1:utf-8')
      Encoding.find('iso-8859-1')
    ensure
      tempfile.rewind
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