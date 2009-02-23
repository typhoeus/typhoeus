# just a brainstorming area where I can play around with different looks for the API

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

@results = []
@pages = []
HTTPMachine.service_access do
  YahooBOSS.web_search("paul dix") do |results|
    results.each {|result| @result[result.id]}
    
    results.each do |result|
      Page.get(result.url) {|page| @pages << page}
    end
  end
  
  YahooBOSS.web_search("joe") do |results|
    @results << results
    
    results.each do |result|
      Page.get(result.url) {|page| @pages << page}
    end
  end
end

