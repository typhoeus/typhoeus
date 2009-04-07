# just a brainstorming area where I can play around with different looks for the API

# one example
results = HTTPMachine.service_access(:web_search => ["paul dix"], :web_search => ["ruby", "nyc"])
results[:web_search] # => [[return_results, pages], [return_results, pages]]

def self.web_search(*args)
  return_results = []
  pages = []
  YahooBOSS.web_search(*args) do |results|
    Page.get {|page| pages << page}
  end
  return [return_results, pages]
end

# another example
@results = []
@pages = []
HTTPMachine.service_access do
  YahooBOSS.web_search("paul dix") do |results|
    @results += results

    results.each do |result|
      Page.get(result.url) {|page| @pages << page }
    end
  end
  
  Twitter.search("whatev") do |results|
    # do stuff here
  end
  
  YahooBOSS.web_search("joe") do |results|
    @results += results
    @
    results.each do |result|
      Page.get(result.url) {|page| @pages << page}
    end
  end
end

YahooBOSS.web_search("http-machine") do |results|
  results.each do |result|
    Page.get(result.url) {|page| puts page}
  end
end

# yet another example
@results = []
HTTPMachine.service_access do
  @results += YahooBOSS.web_search("paul dix").get_pages
  @results += YahooBOSS.web_search("feedzirra").get_pages
end

HTTPMachine.service_access do
  YahooBOSS.remote(:web_search, :params => {:q => "paul dix"})
end