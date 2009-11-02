# -*- encoding: utf-8 -*-
 
Gem::Specification.new do |s|
  s.name = %q{typhoeus}
  s.version = "0.1.8"
 
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Paul Dix"]
  s.date = %q{2009-07-03}
  s.email = %q{paul@pauldix.net}
  s.files = [
    "ext/typhoeus/extconf.rb",
    "ext/typhoeus/typhoeus_easy.h",
    "ext/typhoeus/typhoeus_easy.c",
    "ext/typhoeus/typhoeus_multi.h",
    "ext/typhoeus/typhoeus_multi.c",
    "ext/typhoeus/Makefile",
    "ext/typhoeus/native.h",
    "ext/typhoeus/native.c",
    "lib/typhoeus.rb",
    "lib/typhoeus/easy.rb",
    "lib/typhoeus/multi.rb",
    "lib/typhoeus/remote.rb",
    "lib/typhoeus/remote_proxy_object.rb",
    "lib/typhoeus/filter.rb",
    "lib/typhoeus/remote_method.rb",
    "lib/typhoeus/response.rb",
    "lib/typhoeus/hydra.rb",
    "lib/typhoeus/request.rb",
    "spec/spec.opts",
    "spec/spec_helper.rb",
    "spec/typhoeus/easy_spec.rb",
    "spec/typhoeus/multi_spec.rb",
    "spec/typhoeus/remote_spec.rb",
    "spec/typhoeus/remote_proxy_object_spec.rb",
    "spec/typhoeus/filter_spec.rb",
    "spec/typhoeus/remote_method_spec.rb",
    "spec/typhoeus/response_spec.rb",
    "spec/servers/app.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/pauldix/typhoeus}
  s.require_paths = ["lib", "ext"]
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{A library for interacting with web services (and building SOAs) at blinding speed.}
  s.extensions << 'ext/typhoeus/extconf.rb'
 
  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2
 
    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rack>, ["> 0.9.0"])
    else
      s.add_dependency(%q<rack>, [">= 0.9.0"])
    end
  else
    s.add_dependency(%q<rack>, [">= 0.9.0"])
  end
end
