require "spec_helper"

describe FileProcessor::CSV do
  let(:filename) { fixture('base.csv') }
  let(:options) { {} }

  subject(:processor) { FileProcessor::CSV.new(open(filename), options) }

  it "delegates to a CSV instance" do
    processor.__getobj__.should be_a(::CSV)
  end

  describe "#col_sep" do
    context "when it is not given" do
      context "and the first line of the file has more than one header column separated with a semi-colon" do
        it "detects it properly" do
          processor.col_sep.should eq(';')
        end
      end

      context "and the first line of the file has more than one header column separated with a comman" do
        let(:filename) { fixture('base-with-comma-separated-header.csv') }

        it "detects it properly" do
          processor.col_sep.should eq(',')
        end
      end

      context "and an unknown column separator is used" do
        let(:filename) { fixture('base-with-unknown-column-separator.csv') }

        it "does not detects it, falling back to the default one" do
          processor.col_sep.should eq(',')
        end
      end

      context "and the file has non-ascii characters in its first line" do
        context "in UTF-8" do
          let(:filename) { fixture('base-non-ascii-characters-in-header-utf-8.csv') }

          it "detects it properly" do
            processor.col_sep.should eq(';')
          end
        end

        context "in ISO-8859-1" do
          let(:filename) { fixture('base-non-ascii-characters-in-header-iso-8859-1.csv') }

          it "detects it properly" do
            processor.col_sep.should eq(';')
          end
        end
      end
    end

    context "when it is given" do
      let(:options) { { col_sep: '|' } }

      it "uses the given col_sep" do
        processor.col_sep.should eq('|')
      end
    end
  end

  describe "#count" do
    it "returns the number of rows in the CSV" do
      processor.count.should eq(5)
    end

    it "works even when called multiple times, since it rewinds the io file" do
      processor.count
      processor.count.should eq(5)
    end

    context "when the file has new line characters in a field, but it is properly quoted" do
      let(:filename) { fixture('base-new-line-in-field.csv') }

      it "returns the correct number of rows in the CSV" do
        processor.count.should eq(3)
      end
    end

    context "when the file has blank lines" do
      let(:filename) { fixture('base-with-blank-lines.csv') }

      it "skips them by default" do
        processor.count.should eq(5)
      end
    end

    context "when the file has lines with no data" do
      let(:filename) { fixture('base-with-lines-with-no-data.csv') }

      it "does not count them" do
        processor.count.should eq(5)
      end

      context "but skip_blanks is false" do
        let(:options) { { skip_blanks: false } }

        it "does counts them" do
          processor.count.should eq(7)
        end
      end
    end
  end

  describe "#encoding" do
    context "when the file is in US-ASCII" do
      it "reads it with utf-8" do
        processor.encoding.should eq(Encoding.find('utf-8'))
      end
    end

    it "can iterate through all of its contents without raising an error" do
      expect {
        processor.each {}
      }.to_not raise_error
    end

    context "when the file can be read in utf-8" do
      let(:filename) { fixture('base-utf-8.csv') }

      it "properly detects it" do
        processor.encoding.should eq(Encoding.find('utf-8'))
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

        it "properly detects it, transcoding it to utf-8" do
          processor.encoding.should eq(Encoding.find('utf-8'))
        end

        it "can iterate through all of its contents without raising an error" do
          expect {
            processor.each {}
          }.to_not raise_error
        end

        context "and no look-ahead is used" do
          let(:options)  { { row_sep: "\n" } }

          it "properly detects it, transcoding it to utf-8" do
            processor.encoding.should eq(Encoding.find('utf-8'))
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
      processor.shift.should eq(['A', 'B', 'C']) # first line decompressed
    end

    it { should be_gzipped }

    context "when the file is in ISO-8859-1 encoding" do
      let(:filename) { fixture('base-iso-8859-1.csv.gz') }

      it "detects that the file is gzipped and decompress it" do
        processor.shift.should eq(['A', 'B', 'C']) # first line decompressed
      end

      it { should be_gzipped }
    end

    context "when { gzipped: false } options is passed" do
      let(:options)  { { gzipped: false } }

      context "and the file is not gzipped" do
        let(:filename) { fixture('base.csv') }

        it { should_not be_gzipped }

        it "does not raise an error" do
          expect {
            processor.shift
          }.to_not raise_error
        end
      end

      context "and the file is gzipped" do
        it "does not attempt to detect it, reading data as it were UTF-8" do
          processor.shift.should_not eq(['A', 'B', 'C'])
        end
      end
    end

    context "when { gzipped: true } option is passed" do
      let(:options)  { { gzipped: true } }

      context "and the file is not gzipped" do
        let(:filename) { fixture('base.csv') }

        it { should_not be_gzipped }

        it "does not raise an error" do
          expect {
            processor.shift
          }.to_not raise_error
        end
      end

      context "and the file is gzipped" do
        it "properly assumes that the file is gzipped and decompress it" do
          processor.shift.should eq(['A', 'B', 'C']) # first line decompressed
        end
      end
    end
  end
end