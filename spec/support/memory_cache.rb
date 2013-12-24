class MemoryCache
  def initialize
    @memory = {}
  end

  def get(request)
    @memory[key_for(request)]
  end

  def set(request, response)
    @memory[key_for(request)] = response
  end

  private

  def key_for(request)
    # Using #to_s here makes this class act more like caches like memcached
    # where the keys must be strings.
    request.to_s
  end
end
