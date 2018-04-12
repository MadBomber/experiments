# See Article:  https://medium.com/@tjdracz/interactive-debug-sessions-in-rspec-with-capybara-6c4dec2619d3



require "rails_helper"

RSpec.feature "Sending emails", js: true, type: :feature do
  scenario "sending emails to users" do
    visit email_sender_path
    click_link "Email"
    within "#email-form" do
      fill_in "Email message", with: "Test message"
      click_button "Send"
    end
    expect(page).to have_content("Email sent")
  end
end


include Warden::Test::Helpers

def interactive_debug_session(log_in_as = nil)
  return unless Capybara.current_driver == Capybara.javascript_driver
  return unless current_url
  login_as(log_in_as, scope: :user) if log_in_as.present?
  Launchy.open(current_url)
  binding.pry
end

