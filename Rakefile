# -*- ruby -*-

require 'rubygems'
require 'rake'
require 'rake/clean'
require "spec/rake/spectask"

# Tasks
task :default => [:spec]

desc "Run unit specs"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.libs << 'lib'
  t.spec_opts = ["--format", "specdoc", "--colour"]
  t.spec_files = FileList["spec/**/*_spec.rb"]
end
