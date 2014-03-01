name = "gem_on_demand"
require "./lib/#{name}/version"

Gem::Specification.new name, GemOnDemand::VERSION do |s|
  s.summary = "Run your own gem server that fetches from github, uses tags as version and builds gems on demand"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "https://github.com/grosser/#{name}"
  s.files = `git ls-files lib MIT-LICENSE.txt`.split("\n")
  s.license = "MIT"
  s.add_runtime_dependency "sinatra"
  cert = File.expand_path("~/.ssh/gem-private-key-grosser.pem")
  if File.exist?(cert)
    s.signing_key = cert
    s.cert_chain = ["gem-public_cert.pem"]
  end
end
