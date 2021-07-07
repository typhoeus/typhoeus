require 'spec_helper'

describe Typhoeus::Pooling::Easies do
  let(:easies) { described_class }
  let(:pool) { easies.instance_variable_get('@pool') }
  let(:easy) { Ethon::Easy.new }
  after { easies.clear }

  describe "#release" do
    it "resets easy" do
      expect(easy).to receive(:reset)
      easies.release(easy)
    end

    it "flush cookies to disk" do
      expect(easy).to receive(:cookielist=).with('flush')
      expect(easy).to receive(:reset)
      expect(easy).to receive(:cookielist=).with('all')
      easies.release(easy)
    end

    it "writes cookies to disk" do
      tempfile1 = Tempfile.new('cookies')
      tempfile2 = Tempfile.new('cookies')

      easy.cookiejar = tempfile1.path
      easy.url = "localhost:3001/cookies-test"
      easy.perform

      easies.release(easy)

      expect(File.zero?(tempfile1.path)).to be(false)
      expect(File.read(tempfile1.path)).to match(/\s+foo\s+bar$/)
      expect(File.read(tempfile1.path)).to match(/\s+bar\s+foo$/)

      # do it again - and check if tempfile1 wasn't change
      easy.cookiejar = tempfile2.path
      easy.url = "localhost:3001/cookies-test2"
      easy.perform

      easies.release(easy)

      # tempfile 1
      expect(File.zero?(tempfile1.path)).to be(false)
      expect(File.read(tempfile1.path)).to match(/\s+foo\s+bar$/)
      expect(File.read(tempfile1.path)).to match(/\s+bar\s+foo$/)

      # tempfile2
      expect(File.zero?(tempfile2.path)).to be(false)
      expect(File.read(tempfile2.path)).to match(/\s+foo2\s+bar$/)
      expect(File.read(tempfile2.path)).to match(/\s+bar2\s+foo$/)
    end

    it "puts easy back into pool" do
      expect(pool).to receive(:release).with(easy)
      easies.release(easy)
    end
  end

  describe "#get" do
    context "when easy in pool" do
      before { pool.resources << easy }

      it "takes" do
        expect(easies.get).to eq(easy)
      end
    end

    context "when no easy in pool" do
      it "creates" do
        expect(easies.get).to be_a(Ethon::Easy)
      end
    end
  end

  describe "#with" do
    it "is re-entrant" do
      array = []
      easies.with_easy do |e1|
        array << e1
        easies.with_easy do |e2|
          array << e2
          easies.with_easy do |e3|
            array << e3
          end
        end
      end
      expect(array.uniq.size).to eq(3)
    end
  end
end
