module FileProcessor
  class CSV
    def initialize(filename, options)
      @filename = filename
      @options  = default_options.merge(options)

      @options[:encoding] ||= detect_encoding

      @csv = ::CSV.new(io, @options)
    end

    def col_sep
      @csv.col_sep
    end

    def encoding
      @csv.encoding
    end

    def count
      @csv.rewind
      @csv.count do |row|
        !@csv.skip_blanks? || row.any? { |column| !column.nil? && !column.empty? }
      end
    ensure
      @csv.rewind
    end

    private

    def io
      @io ||= ::Kernel.open(@filename, "rb")
    end

    # We open the file and try to read each line of it, if there is an
    # invalid byte sequence, an ArgumentError exception will be thrown.
    #
    # We then assume that the file is in ISO-8859-1 encoding, and transcode
    # it to UTF-8. Though its ugly, this was the only way to detect whether
    # a file was using one of these encodings.
    def detect_encoding
      utf_io = ::Kernel.open(io, 'r:utf-8')

      ::CSV.new(utf_io, @options).each {}

      @io = utf_io
      Encoding.find('utf-8')
    rescue ArgumentError
      @io = ::Kernel.open(io, 'r:iso-8859-1:utf-8')
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
        col_sep: detect_column_separator,
        skip_blanks: true
      }
    end
  end
end