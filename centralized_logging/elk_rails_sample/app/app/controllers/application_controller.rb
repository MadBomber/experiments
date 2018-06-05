class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  private

  def append_info_to_payload(payload)
    super

    payload[:request_ip] = request.ip
  end
end
