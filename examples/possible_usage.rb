# just a brainstorming area where I can play around with different looks for the API
@results = []
@pages = []
HTTPMachine.service_access do
  YahooBOSS.web_search("paul dix") do |results|
    @results = results
    results.map do |result| 
      Page.get(result.url) {|page| @pages << page}
    end
  end
end

@results = {}
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