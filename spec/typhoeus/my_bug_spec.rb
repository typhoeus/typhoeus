require 'spec_helper'
require 'pp'

# describe '#153' do
#   let(:url) { "http://us.asos.com" }
#   let(:easy) { Typhoeus::Easy.new }

#   context "second" do
#     before { easy.url = url; easy.verbose = 1 }

#     it "works" do
#       easy.perform.should_not eq(400)
#     end
#   end
# end

# describe "#150" do
#   it "works" do
#     p "========================================= start"
#     Typhoeus::Hydra.hydra.disable_memoization
#     100000.times{
#       Typhoeus::Request.post("localhost:3000", body: "")
#     }
#     pp ObjectSpace.count_objects.sort_by{ |_,num| num }
#     types = Hash.new(0)
#     ObjectSpace.each_object do |o|
#       types[o.class] += 1
#     end
#     pp types.sort_by{ |klass,num| num }
#     p "========================================= GC.start"
#   end
# end
