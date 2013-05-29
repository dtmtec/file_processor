require "spec_helper"

describe FileProcessor::Tempfile do
  subject(:temp_file) { FileProcessor::Tempfile.new }
  let(:generated_path) { File.join(Dir.tmpdir, 'some-path') }

  it "creates the file" do
    File.exists?(temp_file.path).should be_true
  end

  it "opens file ready to be written" do
    expect {
      temp_file << "some content"
    }.to_not raise_error
  end

  describe "#path" do
    it "is generated using 'file-processor' basename" do
      temp_file.path.start_with?(File.join(Dir.tmpdir, 'file-processor')).should be_true
    end
  end

  describe "#reopen" do
    let!(:old_file) { temp_file.__getobj__ }

    it "closes the old file" do
      old_file.should_receive(:close)
      temp_file.reopen('r')
    end

    it "updates the delegated object" do
      temp_file.reopen('r')
      temp_file.__getobj__.should_not eq(old_file)
      temp_file.__getobj__.should be_a(File)
    end

    it "reopens the path with the given mode" do
      temp_file.stub!(:path).and_return(generated_path)
      File.should_receive(:open).with(generated_path, 'r:utf-8', 384)
      temp_file.reopen('r:utf-8')
    end

    context "when the old file is already closed" do
      it "does not closes the old file" do
        old_file.close
        old_file.should_not_receive(:close)
        temp_file.reopen('r')
      end
    end
  end
end
