module FileProcessor
  class CSV < SimpleDelegator
    def initialize(filename, options={})
      @filename = filename
      @gzipped  = options.delete(:gzipped)
      @options  = default_options.merge(options)

      @options[:col_sep]  ||= detect_column_separator
      @options[:encoding] ||= detect_encoding

      super(::CSV.new(io, @options))
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

    def io
      @io ||= load_with('rb')
    end

    def detect_compression?
      @gzipped.nil?
    end

    def load_with(mode)
      decompress(::Kernel.open(@filename, mode))
    end

    def decompress(loaded_io)
      if detect_compression? || gzipped?
        Zlib::GzipReader.open(loaded_io).tap do |compressed_io|
          compressed_io.getc # attempt to read from a compressed io
          compressed_io.rewind
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
      utf_io = load_with('r:utf-8')

      ::CSV.new(utf_io, @options).each {}

      @io = utf_io
      Encoding.find('utf-8')
    rescue ArgumentError
      @io = load_with('r:iso-8859-1:utf-8')
      Encoding.find('iso-8859-1')
    ensure
      io.rewind
    end

    def detect_column_separator
      @col_sep = io.gets.split(';').size > 1 ? ';' : ','
    ensure
      io.rewind
    end

    def default_options
      {
        skip_blanks: true
      }
    end
  end
end