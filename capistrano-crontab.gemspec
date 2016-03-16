# -*- encoding: utf-8 -*-
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib)
require "capistrano/crontab/version"

Gem::Specification.new do |gem|
  gem.name = "capistrano-crontab"
  gem.version = Capistrano::Crontab::VERSION
  gem.authors = [ "Jan Pieper" ]
  gem.email = [ "tech@kumukan.com" ]
  gem.description = "Crontab DSL for Capistrano."
  gem.summary = "Capistrano plugin for crontab DSL extension, to add/update/remove cronjobs."
  gem.homepage = "https://github.com/KumukanGmbH/capistrano-crontab"
  gem.license = "MIT"

  gem.files = `git ls-files`.split($/)
  gem.executables = gem.files.grep(%r{bin/}).map { |f| File.basename(f) }
  gem.test_files = gem.files.grep(%r{spec/})
  gem.require_paths = [ "lib" ]

  gem.add_dependency "capistrano", ">= 3.0"
  gem.add_dependency "sshkit", ">= 1.2"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec", ">= 3.0"
end
