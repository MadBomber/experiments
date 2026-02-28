# Rails Testing Skills (RSpec)

> **Framework:** RSpec
> **Data:** Choice of **FactoryBot** or **Fixtures** (Determined by Developer)
> **Stack:** Shoulda Matchers, Capybara/Cuprite

## 1. Configuration (`spec/rails_helper.rb`)

Ensure you have these configurations for optimal performance and DX.

```ruby
RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  
  # FactoryBot syntax methods (create, build)
  config.include FactoryBot::Syntax::Methods
end
```

## 2. Directory Structure

- `spec/models`: Unit tests.
- `spec/requests`: API/Controller integration tests.
- `spec/system`: E2E tests (Capybara).
- `spec/factories`: Factory definitions.
- `spec/support`: Shared configs.

## 3. Best Practices

### Request Specs (The new "Controller" specs)
Test the full stack from routing to response.

```ruby
RSpec.describe "Posts", type: :request do
  describe "POST /posts" do
    it "creates a post and redirects" do
      user = create(:user)
      # Auth via session (Native Rails Auth pattern)
      post sessions_path, params: { email_address: user.email_address, password: user.password }
      
      post posts_path, params: { post: { title: "New" } }
      
      expect(response).to redirect_to(assigns(:post))
      expect(flash[:notice]).to be_present
    end
  end
end
```

### System Specs (UI Testing)
Use `cuprite` or `selenium-headless`.

```ruby
RSpec.describe "Posting", type: :system do
  it "allows user to post" do
    user = create(:user)
    # Manual login or helper for native auth
    visit new_session_path
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: user.password
    click_on "Sign in"
    
    visit new_post_path
    fill_in "Title", with: "Hello World"
    click_on "Publish"
    
    expect(page).to have_content("Post published")
  end
end
```

### Shoulda Matchers (One-liners)
```ruby
it { is_expected.to validate_presence_of(:title) }
it { is_expected.to belong_to(:user) }
it { is_expected.to have_many(:comments) }
```
