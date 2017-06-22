# frozen_string_literal: true

module Assets
  MANIFEST_PATH = Rails.root.join("public/dist/manifest.json")

  private

  def path_to_asset(source, options = {})
    raise ArgumentError, "nil is not a valid asset source" if source.nil?

    source = source.to_s
    return "" unless source.present?
    return source if source =~ ActionView::Helpers::AssetUrlHelper::URI_REGEXP

    tail = source[/([\?#].+)$/]
    source = source.sub(/([\?#].+)$/, "".freeze)

    if (extname = compute_asset_extname(source, options))
      source = "#{source}#{extname}"
    end

    source = File.join("/assets", manifest.fetch(source))

    if (host = compute_asset_host(source, options))
      source = File.join(host, source)
    end

    "#{source}#{tail}"
  end

  def parse_manifest
    JSON.parse(MANIFEST_PATH.read)
  end

  if Rails.env.production?
    def manifest
      @manifest ||= parse_manifest
    end
  else
    alias_method :manifest, :parse_manifest
  end
end
