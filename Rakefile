require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require "spec/rake/spectask"

task :default => [:spec]

desc "Run specs"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.libs << 'lib'
  t.spec_opts = ["--format", "specdoc", "--colour"]
  t.spec_files = FileList["spec/**/*_spec.rb"]
end

gemspec = Gem::Specification.new do |s|
  s.author = 'Samuel Tesla'
  s.email = 'samuel.tesla@gmail.com'
  s.extra_rdoc_files = ['README.rdoc']
  s.files = FileList['Rakefile', '{bin,lib,spec}/**/*']
  s.has_rdoc = true
  s.homepage = 'http://github.com/stesla/muon-core'
  s.name = 'muon-core'
  s.requirements << 'none'
  s.summary = 'Library for connecting to MU* games'
  s.version = '0.1.0'
end

Rake::GemPackageTask.new(gemspec) do |pkg|
  pkg.need_tar = true
end
