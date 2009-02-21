class Parent
  def self.add(method)
    @methods ||= {}
    @methods[method] = "here"
  end
  
  def self.methods
    @methods
  end
end

class Foo < Parent
  add "hello"
end

class Bar < Parent
  add "world"
end

puts Foo.methods.inspect
puts Bar.methods.inspect
puts Parent.methods.inspect