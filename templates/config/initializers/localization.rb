Rails.env.on(:any) do
  config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.yml")]
  config.time_zone = <%= app_const %>::Config.tz
end
