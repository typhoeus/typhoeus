# frozen_string_literal: true

require 'spec_helper'

describe Typhoeus::Response::Header do
  let(:raw) { nil }
  let(:header) { Typhoeus::Response::Header.new(raw) }

  describe ".new" do
    context "when string" do
      let(:raw) { 'Date: Fri, 29 Jun 2012 10:09:23 GMT' }

      it "sets Date" do
        expect(header['Date']).to eq('Fri, 29 Jun 2012 10:09:23 GMT')
      end

      it "provides case insensitive access" do
        expect(header['DaTe']).to eq('Fri, 29 Jun 2012 10:09:23 GMT')
      end

      it "provides symbol access" do
        expect(header[:date]).to eq('Fri, 29 Jun 2012 10:09:23 GMT')
      end

      it "provides case insensitive include? and aliases" do
        expect(header.include?('DaTe')).to eq(true)
        expect(header.key?('DaTe')).to eq(true)
        expect(header.has_key?('DaTe')).to eq(true)
        expect(header.member?('DaTe')).to eq(true)
      end

      it "provides symbol include? and aliases" do
        expect(header.include?(:date)).to eq(true)
        expect(header.key?(:date)).to eq(true)
        expect(header.has_key?(:date)).to eq(true)
        expect(header.member?(:date)).to eq(true)
      end

      it "provides case insensitive fetch" do
        expect(header.fetch('DaTe')).to eq('Fri, 29 Jun 2012 10:09:23 GMT')
        expect(header.fetch('foo', 'default')).to eq('default')
        expect(header.fetch('foo') { |key| key }).to eq('foo')
      end

      it "provides symbol fetch" do
        expect(header.fetch(:date)).to eq('Fri, 29 Jun 2012 10:09:23 GMT')
        expect(header.fetch(:foo, 'default')).to eq('default')
        expect(header.fetch(:foo) { |key| key }).to eq('foo')
      end

      it "provides case insensitive dig" do
        expect(header.dig('DaTe')).to eq('Fri, 29 Jun 2012 10:09:23 GMT')
      end

      it "provides symbol dig" do
        expect(header.dig(:date)).to eq('Fri, 29 Jun 2012 10:09:23 GMT')
      end

      it "returns nil for a missing dig key" do
        expect(header.dig(:foo)).to be_nil
      end

      it "provides case insensitive assoc" do
        expect(header.assoc('DaTe')).to eq(['date', 'Fri, 29 Jun 2012 10:09:23 GMT'])
      end

      it "provides symbol assoc" do
        expect(header.assoc(:date)).to eq(['date', 'Fri, 29 Jun 2012 10:09:23 GMT'])
      end

      it "provides case insensitive values_at" do
        expect(header.values_at('DaTe')).to eq(['Fri, 29 Jun 2012 10:09:23 GMT'])
      end

      it "provides symbol values_at" do
        expect(header.values_at(:date)).to eq(['Fri, 29 Jun 2012 10:09:23 GMT'])
      end

      it "provides case insensitive fetch_values" do
        expect(header.fetch_values('DaTe')).to eq(['Fri, 29 Jun 2012 10:09:23 GMT'])
        expect(header.fetch_values('DaTe', 'foo') { |key| key }).to eq(['Fri, 29 Jun 2012 10:09:23 GMT', 'foo'])
      end

      it "provides symbol fetch_values" do
        expect(header.fetch_values(:date)).to eq(['Fri, 29 Jun 2012 10:09:23 GMT'])
        expect(header.fetch_values(:date, :foo) { |key| key }).to eq(['Fri, 29 Jun 2012 10:09:23 GMT', 'foo'])
      end
    end

    context "when hash" do
      let(:raw) { { 'Date' => 'Fri, 29 Jun 2012 10:09:23 GMT' } }

      it "sets Date" do
        expect(header['Date']).to eq(raw['Date'])
      end

      it "provides case insensitive access" do
        expect(header['DaTe']).to eq(raw['Date'])
      end
    end

    context "when hash with symbol keys" do
      let(:raw) { { :Date => 'Fri, 29 Jun 2012 10:09:23 GMT' } }

      it "sets Date" do
        expect(header['Date']).to eq(raw[:Date])
      end

      it "provides case insensitive access" do
        expect(header['DaTe']).to eq(raw[:Date])
      end
    end

    context "when another header" do
      let(:raw) { Typhoeus::Response::Header.new("A: 1\r\nA: 2") }

      it "copies the values" do
        expect(header["A"]).to eq(["1", "2"])
      end
    end
  end

  describe "#dup" do
    let(:raw) { "A: 1\r\nA: 2" }

    it "does not share the delegated hash" do
      copy = header.dup
      copy["B"] = "3"

      expect(header["B"]).to be_nil
      expect(copy["B"]).to eq("3")
    end

    it "does not share header value arrays" do
      copy = header.dup
      copy["A"] << "3"

      expect(header["A"]).to eq(["1", "2"])
      expect(copy["A"]).to eq(["1", "2", "3"])
    end

    it "keeps the copied hash in sync with the copied index" do
      copy = header.dup
      copy["A"] << "3"

      expect(copy.to_hash["A"]).to eq(["1", "2", "3"])
    end

    it "does not share header value strings" do
      header["C"] = "3"
      copy = header.dup
      copy["C"] << "!"

      expect(header["C"]).to eq("3")
      expect(copy["C"]).to eq("3!")
      expect(copy.to_hash["C"]).to eq("3!")
    end

    it "does not share the delegated hash with clone" do
      copy = header.clone
      copy["B"] = "3"

      expect(header["B"]).to be_nil
    end

    it "keeps the copy independent when cloning with a freeze" do
      skip if RUBY_VERSION < "3.1"

      copy = header.clone(freeze: true)

      expect(copy).to be_frozen
      expect(copy["A"]).to eq(["1", "2"])
    end
  end

  describe "#parse" do
    context "when no header" do
      it "returns nil" do
        expect(header).to be_empty
      end
    end

    context "when header" do
      let(:raw) do
        'HTTP/1.1 200 OK
        Set-Cookie: NID=61=LblqYgUOu; expires=Sat, 29-Dec-2012 10:09:23 GMT; path=/; domain=.google.de; HttpOnly
        Date: Fri, 29 Jun 2012 10:09:23 GMT
        Expires: -1
        Cache-Control: private, max-age=0
        Content-Type: text/html; charset=ISO-8859-1
        Set-Cookie: PREF=ID=77e93yv0hPtejLou; expires=Sun, 29-Jun-2014 10:09:23 GMT; path=/; domain=.google.de
        Set-Cookie: NID=61=LblqYgh5Ou; expires=Sat, 29-Dec-2012 10:09:23 GMT; path=/; domain=.google.de; HttpOnly
        P3P: CP="This is not a P3P policy! See http://www.google.com/support/accounts/bin/answer.py?hl=en&answer=151657 for more info."
        Server: gws
        X-XSS-Protection: 1; mode=block
        X-Frame-Options: SAMEORIGIN
        Vary: Accept-Encoding
        vary: Origin
        Transfer-Encoding: chunked'.gsub(/^\s{8}/, '')
      end

      it "sets raw" do
        expect(header.send(:raw)).to eq(raw)
      end

      it "sets Set-Cookie" do
        expect(header['set-cookie'].size).to eq(3)
      end

      it "provides case insensitive access" do
        expect(header['Set-CooKie'].size).to eq(3)
      end

      it "provides case insensitive access when underlying headers were mixed case" do
        expect(header['Vary'].size).to eq(2)
        expect(header['VaRy'].size).to eq(2)
        expect(header['vary'].size).to eq(2)
      end

      [
        'NID=61=LblqYgUOu; expires=Sat, 29-Dec-2012 10:09:23 GMT; path=/; domain=.google.de; HttpOnly',
        'PREF=ID=77e93yv0hPtejLou; expires=Sun, 29-Jun-2014 10:09:23 GMT; path=/; domain=.google.de',
        'NID=61=LblqYgh5Ou; expires=Sat, 29-Dec-2012 10:09:23 GMT; path=/; domain=.google.de; HttpOnly'
      ].each_with_index do |cookie, i|
        it "sets Cookie##{i}" do
          expect(header['set-cookie']).to include(cookie)
        end
      end

      {
        'Date' => 'Fri, 29 Jun 2012 10:09:23 GMT', 'Expires' => '-1',
        'Cache-Control' => 'private, max-age=0',
        'Content-Type' => 'text/html; charset=ISO-8859-1',
        'P3P' => 'CP="This is not a P3P policy! See http://www.google.com/support/accounts/bin/answer.py?hl=en&answer=151657 for more info."',
        'Server' => 'gws', 'X-XSS-Protection' => '1; mode=block',
        'X-Frame-Options' => 'SAMEORIGIN', 'Transfer-Encoding' => 'chunked'
      }.each do |name, value|
        it "sets #{name}" do
          expect(header[name.downcase]).to eq(value)
        end
      end

      context 'includes a multi-line header' do
        let(:raw) do
          'HTTP/1.1 200 OK
          Date: Fri, 29 Jun 2012 10:09:23 GMT
          Content-Security-Policy: default-src "self";
            img-src * data: "self";
            upgrade-insecure-requests;'.gsub(/^\s{10}/, '')
        end

        it "joins header parts" do
          expect(header).to eq({
            'Date' => 'Fri, 29 Jun 2012 10:09:23 GMT',
            'Content-Security-Policy' => 'default-src "self"; img-src * data: "self"; upgrade-insecure-requests;'
          })
        end
      end

      context 'includes line with only whitespace' do
        let(:raw) do
          'HTTP/1.1 200 OK
          Date: Fri, 29 Jun 2012 10:09:23 GMT
            
          '.gsub(/^\s{10}/, '')
        end

        it 'ignores it' do
          expect(header).to eq({ 'Date' => 'Fri, 29 Jun 2012 10:09:23 GMT' })
        end
      end

      context 'with broken headers' do
        let(:raw) do
          'HTTP/1.1 200 OK
          Date:
          Content-Type
          '.gsub(/^\s{10}/, '')
        end

        it 'returns empty string for invalid headers' do
          expect(header.to_hash).to include({ 'Date' => '', 'Content-Type' => '' })
        end
      end
    end
  end

  it "can be Marshal'd" do
    header = Typhoeus::Response::Header.new("Foo: Bar")
    expect {
      Marshal.dump(header)
    }.not_to raise_error
  end

  describe "mutation" do
    let(:raw) { "A: 1" }

    it "updates case insensitive access on []=" do
      header["A"] = "2"

      expect(header["A"]).to eq("2")
      expect(header["a"]).to eq("2")
      expect(header.to_hash).to eq("A" => "2")
    end

    it "removes duplicate casings on []=" do
      header["a"] = "2"

      expect(header.to_hash.keys).to eq(["a"])
    end

    it "deletes from both stores" do
      expect(header.delete("A")).to eq("1")

      expect(header["A"]).to be_nil
      expect(header.include?("A")).to be(false)
      expect(header.to_hash).to be_empty
    end

    it "clears both stores" do
      header.clear

      expect(header["A"]).to be_nil
      expect(header.to_hash).to be_empty
    end

    it "returns self from clear" do
      expect(header.clear).to be(header)
    end

    it "deletes with a block and keeps lookups in sync" do
      expect(header.delete_if { |key, _| key == "A" }).to be(header)

      expect(header["A"]).to be_nil
      expect(header.key?("a")).to be(false)
    end

    it "keeps with a block and keeps lookups in sync" do
      header.keep_if { |key, _| key == "A" }

      expect(header["A"]).to eq("1")
      expect(header.key?("B")).to be(false)
    end

    it "rejects with a block and keeps lookups in sync" do
      header.reject! { |key, _| key == "A" }

      expect(header.key?("a")).to be(false)
    end

    it "selects with a block and keeps lookups in sync" do
      header["B"] = "2"

      expect(header.select! { |key, _| key == "A" }).to be(header)

      expect(header["A"]).to eq("1")
      expect(header.key?("B")).to be(false)
    end

    it "returns nil from select! when nothing is removed" do
      expect(header.select! { |_, _| true }).to be_nil
    end

    it "filters with a block and keeps lookups in sync" do
      header.filter! { |key, _| key != "A" }

      expect(header.key?("a")).to be(false)
    end

    it "shifts and keeps lookups in sync" do
      expect(header.shift).to eq(["A", "1"])

      expect(header.key?("A")).to be(false)
    end

    it "compacts and keeps lookups in sync" do
      header["B"] = nil

      expect(header.compact!).to be(header)
      expect(header.key?("B")).to be(false)
    end

    it "transforms keys and keeps lookups in sync" do
      header.transform_keys! { |key| key.downcase }

      expect(header["a"]).to eq("1")
      expect(header.key?("A")).to be(true)
    end

    it "transforms keys with a mapping and keeps lookups in sync" do
      skip if RUBY_VERSION < "3.0"

      expect(header.transform_keys!("A" => "C")).to be(header)

      expect(header["C"]).to eq("1")
      expect(header.key?("A")).to be(false)
    end

    it "returns an enumerator for transform_keys! without a block" do
      expect(header.transform_keys!).to be_a(Enumerator)
    end

    it "transforms values and keeps lookups in sync" do
      header.transform_values! { |value| "#{value}!" }

      expect(header["a"]).to eq("1!")
      expect(header["A"]).to eq("1!")
    end

    it "returns an enumerator for delete_if without a block" do
      expect(header.delete_if).to be_a(Enumerator)
    end

    it "uses the update block for conflicting keys" do
      expect(header.merge!("A" => "2") { |_, old, new| "#{old}-#{new}" }).to be(header)
      expect(header["A"]).to eq("1-2")
    end

    it "updates from a hash" do
      header.update("B" => "2", "C" => "3")

      expect(header["b"]).to eq("2")
      expect(header["c"]).to eq("3")
      expect(header.to_hash).to include("B" => "2", "C" => "3")
    end

    it "replaces a hash" do
      header.replace("B" => "2")

      expect(header["A"]).to be_nil
      expect(header["B"]).to eq("2")
      expect(header.to_hash).to eq("B" => "2")
    end

    it "updates a key with a different casing" do
      header.update("a" => "2")

      expect(header["A"]).to eq("2")
      expect(header.to_hash).to eq("a" => "2")
    end

    it "returns nil when deleting a missing key" do
      expect(header.delete("Missing")).to be_nil
    end

    it "returns nil from reject! when nothing is removed" do
      expect(header.reject! { |_, _| false }).to be_nil
    end

    it "returns nil from compact! when there is nothing to remove" do
      expect(header.compact!).to be_nil
    end

    it "returns an enumerator for keep_if without a block" do
      expect(header.keep_if).to be_a(Enumerator)
    end

    it "returns an enumerator for transform_values! without a block" do
      expect(header.transform_values!).to be_a(Enumerator)
    end
  end
end
