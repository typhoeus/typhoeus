# frozen_string_literal: true

# Where the local test server listens. The port is assigned when the suite
# boots so the specs can run next to another checkout.
module TestServer
  class << self
    attr_accessor :port

    def host
      "localhost:#{port}"
    end

    def url
      "http://#{host}"
    end

    def next_id
      @mutex ||= Mutex.new
      @mutex.synchronize { @id = (@id || 0) + 1 }
    end
  end
end
