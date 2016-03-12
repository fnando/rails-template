# Check https://github.com/twitter/secureheaders for documentation.
SecureHeaders::Configuration.default do |config|
  config.csp[:default_src] = %w['self']
end
