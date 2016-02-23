FastlyRails.configure do |c|
  begin
    fastly = CF::App::Credentials
      .find_all_by_all_service_name('fastly')
      .first
    c.api_key    = fastly.fetch('api_key')
    c.service_id = fastly.fetch('service_id')
  rescue
    c.api_key = ENV['FASTLY_API_KEY']
    c.service_id = ENV['FASTLY_SERVICE_ID']
  end
end

