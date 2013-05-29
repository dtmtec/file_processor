module FileProcessor
  class Tempfile < ::Tempfile
    def initialize(basename='file-processor', *args)
      super(basename, *args)
    end

    def path
      @tmpname
    end

    def reopen(mode)
      close unless closed?
      @mode = mode

      @tmpfile = File.open(path, mode, @opts)
      @data[1] = @tmpfile
      __setobj__(@tmpfile)
    end
  end
end