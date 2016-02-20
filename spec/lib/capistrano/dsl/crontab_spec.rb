require "spec_helper"

RSpec.describe Capistrano::DSL do
  let(:dsl) { Class.new { extend Capistrano::DSL } }
  let(:tempfile) { StringIO.new }

  before(:each) do
    allow(Tempfile).to receive(:new).and_wrap_original { tempfile.reopen }
    allow(tempfile).to receive(:path).and_return("/tmp/capistrano-crontab")
    allow(tempfile).to receive(:unlink)

    allow(dsl).to receive(:capture).with(:crontab, "-l").and_wrap_original { tempfile.string }
    allow(dsl).to receive(:upload!)
    allow(dsl).to receive(:execute)
  end

  describe ".crontab_get_content" do
    it "should call .capture with :crontab and '-l' as arguments" do
      expect(dsl).to receive(:capture).once.with(:crontab, "-l")
      dsl.crontab_get_content
    end

    it "should return the return value of the call to .capture" do
      allow(dsl).to receive(:capture).and_return("crontab content\n")
      expect(dsl.crontab_get_content).to eql("crontab content\n")
    end
  end

  describe ".crontab_set_content" do
    context "if upload of tempfile fails" do
      before(:each) do
        expect(dsl).to receive(:upload!)
          .once.with(tempfile.path, tempfile.path)
          .and_raise("Upload failed")
      end

      after(:each) do
        expect { dsl.crontab_set_content("irrelevant") }.to raise_error("Upload failed")
      end

      it "should not update crontab on the server" do
        expect(dsl).not_to receive(:execute).with(:crontab, tempfile.path)
      end

      it "should delete tempfile on the server" do
        expect(dsl).to receive(:execute).once.with(:rm, "-f", tempfile.path)
      end

      it "should delete tempfile locally" do
        expect(tempfile).to receive(:unlink).once
      end
    end

    context "if update of crontab fails" do
      before(:each) do
        expect(dsl).to receive(:execute)
          .once.with(:crontab, tempfile.path)
          .and_raise("Crontab update failed")
      end

      after(:each) do
        expect { dsl.crontab_set_content("Irrelevant") }.to raise_error("Crontab update failed")
      end

      it "should upload tempfile to the server" do
        expect(dsl).to receive(:upload!).once.with(tempfile.path, tempfile.path)
      end

      it "should delete tempfile on the server" do
        expect(dsl).to receive(:execute).once.with(:rm, "-f", tempfile.path)
      end

      it "should delete tempfile locally" do
        expect(tempfile).to receive(:unlink).once
      end
    end

    context "if update of crontab is successful" do
      after(:each) do
        dsl.crontab_set_content("Irrelevant")
      end

      it "should upload tempfile to the server" do
        expect(dsl).to receive(:upload!).once.with(tempfile.path, tempfile.path)
      end

      it "should update crontab on the server" do
        expect(dsl).to receive(:execute).once.with(:crontab, tempfile.path)
      end

      it "should delete tempfile on the server" do
        expect(dsl).to receive(:execute).once.with(:rm, "-f", tempfile.path)
      end

      it "should delete tempfile locally" do
        expect(tempfile).to receive(:unlink)
      end
    end
  end

  describe ".crontab_puts_content" do
    it "should call .crontab_get_content without any args" do
      expect(dsl).to receive(:crontab_get_content).once.with(no_args)
      expect { dsl.crontab_puts_content }.to output.to_stdout
    end

    it "should write the return value of .crontab_get_content to stdout" do
      allow(dsl).to receive(:crontab_get_content).and_return("crontab content\n")
      expect { dsl.crontab_puts_content }.to output("crontab content\n").to_stdout
    end
  end

  describe ".crontab_add_line" do
    before(:each) do
      dsl.crontab_set_content("* * * * * create_snapshot")
    end

    it "should call .crontab_set_content with previous crontab content and new line marked with 'backup'" do
      expect(dsl).to receive(:crontab_set_content).once.with(
        "* * * * * create_snapshot\n" \
        "* * * * * rotate_logs # MARKER:backup"
      )

      dsl.crontab_add_line("* * * * * rotate_logs", "backup")
    end
  end

  describe ".crontab_remove_line" do
    before(:each) do
      dsl.crontab_set_content(
        "* * * * * create_snapshot\n" \
        "* * * * * rotate_logs # MARKER:rotate\n" \
        "* * * * * clear_cache # MARKER:clear"
      )
    end

    it "should call .crontab_set_content with previous crontab content except the line marked with 'rotate'" do
      expect(dsl).to receive(:crontab_set_content).once.with(
        "* * * * * create_snapshot\n" \
        "* * * * * clear_cache # MARKER:clear"
      )

      dsl.crontab_remove_line("rotate")
    end
  end

  describe ".crontab_update_line" do
    before(:each) do
      dsl.crontab_set_content(
        "* * * * * create_snapshot\n" \
        "* * * * * rotate_logs # MARKER:rotate\n" \
        "* * * * * clear_cache # MARKER:clear"
      )
    end

    after(:each) do
      dsl.crontab_update_line("0 0 * * * rotate_logs", "rotate")
    end

    it "should call .crontab_set_content with previous crontab content except the line to be updated" do
      expect(dsl).to receive(:crontab_set_content).once.with(
        "* * * * * create_snapshot\n" \
        "* * * * * clear_cache # MARKER:clear" \
      ).and_call_original

      allow(dsl).to receive(:crontab_set_content)
        .once.with(anything).and_call_original
    end

    it "should call .crontab_set_content with previous crontab content and updated line marked with 'rotate'" do
      allow(dsl).to receive(:crontab_set_content)
        .once.with(anything).and_call_original

      expect(dsl).to receive(:crontab_set_content).with(
        "* * * * * create_snapshot\n" \
        "* * * * * clear_cache # MARKER:clear\n" \
        "0 0 * * * rotate_logs # MARKER:rotate"
      ).and_call_original
    end
  end

  describe ".crontab_marker" do
    it "should return empty marker string if no marker name is given" do
      expect(dsl.crontab_marker).to eql("")
    end

    it "should return ' # MARKER:backup' if marker name is 'backup'" do
      expect(dsl.crontab_marker("backup")).to eql(" # MARKER:backup")
    end
  end
end
