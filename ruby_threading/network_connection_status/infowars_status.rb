class InfoWarsStatus < NetworkConnectionStatus
  URL = 'https://www.infowars.com/watch-alex-jones-show/'

  class << self
    def test
      service_name = name.gsub('Status','').humanize.upcase
      result = web_service_active?(URL)
      return {service_name => result}
    end
  end # class << self
end # class InfoWarsStatus < NetworkConnectionStatus

