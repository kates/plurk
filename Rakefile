require "rake/rdoctask"
require "rake/testtask"
require "rake/gempackagetask"

require "rubygems"

dir     = File.dirname(__FILE__)
lib     = File.join(dir, "lib", "plurk.rb")

spec = Gem::Specification.new do |spec|
  spec.name     = "plurk"
  spec.version  = "2.0"
  spec.platform = Gem::Platform::RUBY
  spec.summary  = "A Plurk ruby client"
  spec.files    = Dir.glob("{lib}/**/*.rb")
  spec.require_path      = 'lib'

  spec.author            = "kates"
  spec.email             = "katesgasis@gmail.com"
  spec.homepage          = "http://github.com/kates/plurk"

  spec.description       = <<END_DESC
An unofficial ruby Plurk client.
END_DESC
  spec.add_dependency("json")
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end