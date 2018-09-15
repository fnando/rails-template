Rails.env.on(:any) do
  config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.yml")]
  config.time_zone = <%= app_const %>::Config.tz
end

Rails.env.on(:development, :test) do
  config.action_view.raise_on_missing_translations = true
end
