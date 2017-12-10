
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "se/realtime/version"

Gem::Specification.new do |spec|
  spec.name          = "se-realtime"
  spec.version       = SE::Realtime::VERSION
  spec.authors       = ["thesecretmaster"]
  spec.email         = ["thesecretmaster@developingtechnician.com"]

  spec.summary       = %q{A SE realtime feed reader}
  spec.homepage      = "https://github.com/izwick-schachter/se-realtime"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"

  [
    ["mechanize",          "~> 2.7"],
    ["nokogiri",           "~> 1.8"],
    ["permessage_deflate", "~> 0.1"],
    ["websocket-driver",   "~> 0.6"],
  ].each do |g, v|
    spec.add_runtime_dependency g, v
  end
end
