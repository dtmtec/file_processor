require "spec_helper"

describe FileProcessor::CSV do
  let(:filename) { fixture('base.csv') }
  let(:options) { {} }

  subject(:processor) { FileProcessor::CSV.new(filename, options) }

  it "delegates to a CSV instance" do
    expect(processor.__getobj__).to be_a(::CSV)
  end

  describe "#col_sep" do
    context "when it is not given" do
      context "and the first line of the file has more than one header column separated with a semi-colon" do
        it "detects it properly" do
          expect(processor.col_sep).to eq(';')
        end
      end

      context "and the first line of the file has more than one header column separated with a comman" do
        let(:filename) { fixture('base-with-comma-separated-header.csv') }

        it "detects it properly" do
          expect(processor.col_sep).to eq(',')
        end
      end

      context "and an unknown column separator is used" do
        let(:filename) { fixture('base-with-unknown-column-separator.csv') }

        it "does not detects it, falling back to the default one" do
          expect(processor.col_sep).to eq(',')
        end
      end

      context "and the file has non-ascii characters in its first line" do
        context "in UTF-8" do
          let(:filename) { fixture('base-non-ascii-characters-in-header-utf-8.csv') }

          it "detects it properly" do
            expect(processor.col_sep).to eq(';')
          end
        end

        context "in ISO-8859-1" do
          let(:filename) { fixture('base-non-ascii-characters-in-header-iso-8859-1.csv') }

          it "detects it properly" do
            expect(processor.col_sep).to eq(';')
          end
        end
      end
    end

    context "when it is given" do
      let(:options) { { col_sep: '|' } }

      it "uses the given col_sep" do
        expect(processor.col_sep).to eq('|')
      end
    end
  end

  describe "#count" do
    it "returns the number of rows in the CSV" do
      expect(processor.count).to eq(5)
    end

    context "when the file has new line characters in a field, but it is properly quoted" do
      let(:filename) { fixture('base-new-line-in-field.csv') }

      it "returns the correct number of rows in the CSV" do
        expect(processor.count).to eq(3)
      end
    end

    context "when the file has blank lines" do
      let(:filename) { fixture('base-with-blank-lines.csv') }

      it "skips them by default" do
        expect(processor.count).to eq(5)
      end
    end

    context "when the file has lines with no data" do
      let(:filename) { fixture('base-with-lines-with-no-data.csv') }

      it "does not count them" do
        expect(processor.count).to eq(5)
      end

      context "but skip_blanks is false" do
        let(:options) { { skip_blanks: false } }

        it "does counts them" do
          expect(processor.count).to eq(7)
        end
      end

      context "and { headers: true } is passed" do
        let(:options) { { headers: true } }

        it "does not count these lines, as well as the header" do
          expect(processor.count).to eq(4)
        end
      end
    end

    context "when a block is passed" do
      let(:filename) { fixture('base-with-lines-with-no-data.csv') }

      it "returns the number of lines for which the block evaluates to true, properly handling lines with no data" do
        expect(processor.count { |row| !row.first.nil? }).to eq(3)
      end
    end
  end

  describe "#total_count" do
    it "works as count, but returns all rows, even when called multiple times, since it rewinds the io file" do
      processor.total_count
      expect(processor.total_count).to eq(5)
    end
  end

  describe "#each" do
    it "returns an enumerator when called without a block" do
      expect(processor.each).to be_a(Enumerator)
    end

    context "when the file has lines with no data" do
      let(:filename) { fixture('base-with-lines-with-no-data.csv') }

      it "does not yields these lines" do
        expect { |block|
          processor.each(&block)
        }.to yield_control.exactly(5).times
      end

      context "but skip_blanks is false" do
        let(:options) { { skip_blanks: false } }

        it "yields these lines" do
          expect { |block|
            processor.each(&block)
          }.to yield_control.exactly(7).times
        end
      end

      context "and { headers: true } is passed" do
        let(:options) { { headers: true } }

        it "does not yields these lines, as well as the header" do
          expect { |block|
            processor.each(&block)
          }.to yield_control.exactly(4).times # header do not count here
        end
      end
    end
  end

  describe "encoding" do
    it "can iterate through all of its contents without raising an error" do
      expect {
        processor.each {}
      }.to_not raise_error
    end

    context "when the encoding is given" do
      let(:filename) { fixture('base-utf-8.csv') }
      let(:options) { { encoding: 'utf-8' } }

      it "returns the proper detected encoding" do
        expect(processor.detected_encoding).to eq(Encoding.find(options[:encoding]))
      end

      it "opens the file properly" do
        expect {
          processor
        }.to_not raise_error
      end

      context "and the file is ISO-8859-1" do
        let(:filename) { fixture('base-iso-8859-1.csv') }

        it "uses it to open the file, raising an error" do
          expect {
            processor
          }.to raise_error(ArgumentError)
        end

        context "but the given encoding is ISO-8859-1" do
          let(:options) { { encoding: 'ISO-8859-1' } }

          it "returns the proper detected encoding" do
            expect(processor.detected_encoding).to eq(Encoding.find(options[:encoding]))
          end

          it "opens the file properly" do
            expect {
              processor
            }.to_not raise_error
          end
        end
      end
    end

    context "when the file is in US-ASCII" do
      it "returns the proper detected encoding" do
        expect(processor.detected_encoding).to eq(Encoding.find('utf-8'))
      end

      it "reads it with utf-8" do
        expect(processor.encoding).to eq(Encoding.find('utf-8'))
      end
    end

    context "when the file can be read in utf-8" do
      let(:filename) { fixture('base-utf-8.csv') }

      it "returns the proper detected encoding" do
        expect(processor.detected_encoding).to eq(Encoding.find('utf-8'))
      end

      it "properly detects it" do
        expect(processor.encoding).to eq(Encoding.find('utf-8'))
      end

      it "can iterate through all of its contents without raising an error" do
        expect {
          processor.each {}
        }.to_not raise_error
      end
    end

    context "when the file cannot be read in utf-8" do
      context "but it can be read in iso-8859-1" do
        let(:filename) { fixture('base-iso-8859-1.csv') }

        it "returns the proper detected encoding" do
          expect(processor.detected_encoding).to eq(Encoding.find('iso-8859-1'))
        end

        it "properly detects it, transcoding it to utf-8" do
          expect(processor.encoding).to eq(Encoding.find('utf-8'))
        end

        it "can iterate through all of its contents without raising an error" do
          expect {
            processor.each {}
          }.to_not raise_error
        end

        context "and no look-ahead is used" do
          let(:options)  { { row_sep: "\n" } }

          it "returns the proper detected encoding" do
            expect(processor.detected_encoding).to eq(Encoding.find('iso-8859-1'))
          end

          it "properly detects it, transcoding it to utf-8" do
            expect(processor.encoding).to eq(Encoding.find('utf-8'))
          end

          it "can iterate through all of its contents without raising an error" do
            expect {
              processor.each {}
            }.to_not raise_error
          end
        end
      end
    end
  end

  describe "gzip support" do
    let(:filename) { fixture('base.csv.gz') }

    it "detects that the file is gzipped and decompress it" do
      expect(processor.shift).to eq(['A', 'B', 'C']) # first line decompressed
    end

    it { is_expected.to be_gzipped }

    context "when the file is in ISO-8859-1 encoding" do
      let(:filename) { fixture('base-iso-8859-1.csv.gz') }

      it "detects that the file is gzipped and decompress it" do
        expect(processor.shift).to eq(['A', 'B', 'C']) # first line decompressed
      end

      it { is_expected.to be_gzipped }
    end

    context "when { gzipped: false } options is passed" do
      let(:options)  { { gzipped: false } }

      context "and the file is not gzipped" do
        let(:filename) { fixture('base.csv') }

        it { is_expected.to_not be_gzipped }

        it "does not raise an error" do
          expect {
            processor.shift
          }.to_not raise_error
        end
      end

      context "and the file is gzipped" do
        it "does not attempt to detect it, reading data as it were UTF-8" do
          expect(processor.shift).to_not eq(['A', 'B', 'C'])
        end
      end
    end

    context "when { gzipped: true } option is passed" do
      let(:options)  { { gzipped: true } }

      context "and the file is not gzipped" do
        let(:filename) { fixture('base.csv') }

        it { is_expected.to_not be_gzipped }

        it "does not raise an error" do
          expect {
            processor.shift
          }.to_not raise_error
        end
      end

      context "and the file is gzipped" do
        it "properly assumes that the file is gzipped and decompress it" do
          expect(processor.shift).to eq(['A', 'B', 'C']) # first line decompressed
        end
      end
    end
  end

  describe "#process_range" do
    it "yields every line of the file by default" do
      expect { |block|
        processor.process_range(&block)
      }.to yield_control.exactly(5).times
    end

    it "yields the row and its index" do
      expect { |block|
        processor.process_range(&block)
      }.to yield_successive_args(
        [["A",  "B",  "C"],  0],
        [["a1", "b1", "c1"], 1],
        [["a2", "b2", "c2"], 2],
        [["a3", "b3", "c3"], 3],
        [["a4", "b4", "c4"], 4]
      )
    end

    it "rewinds the file, so it can be called multiple times" do
      processor.process_range {}

      expect { |block|
        processor.process_range(&block)
      }.to yield_successive_args(
        [["A",  "B",  "C"],  0],
        [["a1", "b1", "c1"], 1],
        [["a2", "b2", "c2"], 2],
        [["a3", "b3", "c3"], 3],
        [["a4", "b4", "c4"], 4]
      )
    end

    context "when an offset is given" do
      let(:offset) { 2 }

      it "starts from this offset" do
        expect { |block|
          processor.process_range(offset: offset, &block)
        }.to yield_successive_args(
          [["a2", "b2", "c2"], 2],
          [["a3", "b3", "c3"], 3],
          [["a4", "b4", "c4"], 4]
        )
      end

      context "and it is equal to the number of lines of the file" do
        let(:offset) { processor.count }

        it "does not yield" do
          expect { |block|
            processor.process_range(offset: offset, &block)
          }.to_not yield_control
        end
      end

      context "and it is greater than to the number of lines of the file" do
        let(:offset) { processor.count + 1 }

        it "does not yield" do
          expect { |block|
            processor.process_range(offset: offset, &block)
          }.to_not yield_control
        end
      end
    end

    context "when a limit is given" do
      let(:limit) { 2 }

      it "yields only the number of rows given" do
        expect { |block|
          processor.process_range(limit: limit, &block)
        }.to yield_successive_args(
          [["A",  "B",  "C"],  0],
          [["a1", "b1", "c1"], 1]
        )
      end

      context "with zero" do
        let(:limit) { 0 }

        it "does not yield" do
          expect { |block|
            processor.process_range(limit: limit, &block)
          }.to_not yield_control
        end
      end

      context "with an offset" do
        let(:offset) { 2 }

        it "yields only the number of rows given, from the given offset" do
          expect { |block|
            processor.process_range(offset: offset, limit: limit, &block)
          }.to yield_successive_args(
            [["a2", "b2", "c2"], 2],
            [["a3", "b3", "c3"], 3]
          )
        end
      end
    end
  end

  describe ".open" do
    subject(:processor) { double(FileProcessor::CSV, close: true) }
    before { allow(FileProcessor::CSV).to receive(:new).with(filename, options).and_return(processor) }

    context "without a block" do
      it "creates a new instance and returns it" do
        expect(FileProcessor::CSV.open(filename, options)).to eq(processor)
      end
    end

    context "with a block" do
      it "creates a new instance and returns it" do
        expect { |block|
          FileProcessor::CSV.open(filename, options, &block)
        }.to yield_with_args(processor)
      end
    end
  end
end
