$:.push File.expand_path("../lib", __FILE__)
require 'semver-tribe'

Gem::Specification.new do |spec|
  spec.name = "semver-tribe"
  spec.version = SemVer.find.format '%M.%m.%p'
  spec.summary = "Semantic Versioning"
  spec.description = "maintain versions as per http://semver.org"
  spec.email = "timmfin@timmfin.dnet"
  spec.authors = ["Francesco Lazzarino", "Henrik Feldt", "Tim Finley"]
  spec.homepage = 'https://github.com/timmfin/semver-tribe'
  spec.executables << 'semver'
  spec.files = [".semver", "semver-tribe.gemspec", "README.md"] + Dir["lib/**/*.rb"] + Dir['bin/*']
  spec.has_rdoc = true
end
