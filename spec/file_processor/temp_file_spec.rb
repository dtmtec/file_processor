require "spec_helper"

describe FileProcessor::Tempfile do
  subject(:temp_file) { FileProcessor::Tempfile.new }
  let(:generated_path) { File.join(Dir.tmpdir, 'some-path') }

  it "creates the file" do
    expect(File.exists?(temp_file.path)).to be_truthy
  end

  it "opens file ready to be written" do
    expect {
      temp_file << "some content"
    }.to_not raise_error
  end

  describe "#path" do
    it "is generated using 'file-processor' basename" do
      expect(temp_file.path.start_with?(File.join(Dir.tmpdir, 'file-processor'))).to be_truthy
    end
  end

  describe "#reopen" do
    let!(:old_file) { temp_file.__getobj__ }

    it "closes the old file" do
      expect(old_file).to receive(:close)
      temp_file.reopen('r')
    end

    it "updates the delegated object" do
      temp_file.reopen('r')
      expect(temp_file.__getobj__).to_not eq(old_file)
      expect(temp_file.__getobj__).to be_a(File)
    end

    it "reopens the path with the given mode" do
      allow(temp_file).to receive(:path).and_return(generated_path)
      expect(File).to receive(:open).with(generated_path, 'r:utf-8', { perm: 384 })
      temp_file.reopen('r:utf-8')
    end

    context "when the old file is already closed" do
      it "does not closes the old file" do
        old_file.close
        expect(old_file).to_not receive(:close)
        temp_file.reopen('r')
      end
    end
  end
end
