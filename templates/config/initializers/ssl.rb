Rails.env.on(:any) do
  config.force_ssl = <%= app_const %>::Config.force_ssl
end
