# -*- encoding: utf-8 -*-
 
Gem::Specification.new do |s|
  s.name = %q{http-machine}
  s.version = "0.0.3"
 
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Paul Dix"]
  s.date = %q{2009-03-12}
  s.email = %q{paul@pauldix.net}
  s.files = [
    "ext/http-machine/extconf.rb",
    "ext/http-machine/http_machine_easy.h",
    "ext/http-machine/http_machine_easy.c",
    "ext/http-machine/http_machine_multi.h",
    "ext/http-machine/http_machine_multi.c",
    "ext/http-machine/Makefile",
    "ext/http-machine/native.h",
    "ext/http-machine/native.c",
    "lib/http-machine.rb",
    "lib/http-machine/easy.rb",
    "lib/http-machine/multi.rb",
    "lib/http-machine/remote.rb",
    "lib/http-machine/filter.rb",
    "lib/http-machine/remote_method.rb",
    "spec/spec.opts",
    "spec/spec_helper.rb",
    "spec/http-machine/easy_spec.rb",
    "spec/http-machine/multi_spec.rb",
    "spec/http-machine/remote_spec.rb",
    "spec/http-machine/filter_spec.rb",
    "spec/http-machine/remote_method_spec.rb",
    "spec/servers/delay_fixture_server.rb",
    "spec/servers/method_server.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/pauldix/http-machine}
  s.require_paths = ["lib", "ext"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{A library for interacting with web services (and building SOAs) at blinding speed.}
  s.extensions << 'ext/http-machine/extconf.rb'
 
  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2
 
    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end