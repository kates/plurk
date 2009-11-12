require "rake/rdoctask"
require "rake/testtask"
require "rake/gempackagetask"

require "rubygems"

dir     = File.dirname(__FILE__)
lib     = File.join(dir, "lib", "plurk.rb")

spec = Gem::Specification.new do |spec|
  spec.name     = "plurk"
  spec.version  = "1.0"
  spec.platform = Gem::Platform::RUBY
  spec.summary  = "A Plurk ruby library"
  spec.files    = Dir.glob("{lib}/**/*.rb")
  spec.require_path      = 'lib'

  spec.author            = "kates"
  spec.email             = "katesgasis@gmail.com"

  spec.description       = <<END_DESC
An unofficial ruby Plurk library.
END_DESC
  spec.add_dependency("mechanize")
  spec.add_dependency("json")
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end