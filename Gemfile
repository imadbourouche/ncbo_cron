source 'https://rubygems.org'

gemspec


# This is needed temporarily to pull the Google Universal Analytics (UA)
# data and store it in a file. See (bin/import_google_ua_analytics_data)
# The ability to pull this data from Google will cease on July 1, 2024
gem "google-apis-analytics_v3"
gem 'google-analytics-data', '0.6.0'
gem 'google-protobuf', '3.25.3'
gem 'mail', '2.6.6'
gem 'multi_json'
gem 'oj'
gem 'parseconfig'
gem 'pony'
gem 'pry'
gem 'rake'
gem 'redis'
gem 'rest-client'
gem 'sys-proctable'
gem 'request_store'
gem 'parallel'
gem 'json-ld'
gem 'ffi', '~> 1.16.3'

# Monitoring
gem 'cube-ruby', require: 'cube'

gem 'goo', github: 'ontoportal-lirmm/goo', branch: 'development'
gem 'sparql-client', github: 'ontoportal-lirmm/sparql-client', branch: 'development'
gem 'ontologies_linked_data', github: 'ontoportal-lirmm/ontologies_linked_data', branch: 'development'
gem 'ncbo_annotator', github: 'ontoportal-lirmm/ncbo_annotator', branch: 'development'
# Testing
group :test do
  gem 'email_spec'
  gem 'minitest', '< 5.0'
  gem 'simplecov'
  gem 'simplecov-cobertura' # for codecov.io
  gem 'test-unit-minitest'
end

group :deployment do
  # bcrypt_pbkdf and ed35519 is required for capistrano deployments when using ed25519 keys; see https://github.com/miloserdow/capistrano-deploy/issues/42
  gem 'bcrypt_pbkdf', '>= 1.0', '< 2.0', require: false
  gem 'capistrano', '~> 3', require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-locally', require: false
  gem 'capistrano-rbenv', require: false
  gem 'ed25519', '>= 1.2', '< 2.0', require: false
end

gem "binding_of_caller", "~> 1.0"
