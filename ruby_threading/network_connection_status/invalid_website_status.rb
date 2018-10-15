class InvalidWebsiteStatus < NetworkConnectionStatus
  URL = 'http://www.invaild_website.com/'

  class << self
    def test
      service_name = name.gsub('Status','').humanize.upcase
      result = web_service_active?(URL)
      return {service_name => result}
    end
  end # class << self
end # class InvalidWebsiteStatus < NetworkConnectionStatus
