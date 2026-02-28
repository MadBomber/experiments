# Rails Testing Skills (Minitest)

> **Framework:** Minitest (Rails Default)
> **Data:** **Fixtures** (Standard) or **FactoryBot** (Choice determined by Developer)
> **Philosophy:** Native, Fast, Simple.

## 1. Test Structure
Follow the standard Rails directory structure.

```ruby
require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user" do
    user = users(:one)
    assert user.valid?
  end
end
```

## 2. Fixtures
We use Fixtures for Minitest (standard), though FactoryBot can be configured.
- **Location:** `test/fixtures/*.yml`
- **Reference:** `users(:alice)`

```yaml
# test/fixtures/users.yml
alice:
  name: Alice Smith
  email: alice@example.com
```

## 3. System Tests (Capybara/Cuprite)
Use standard system tests for UI.

```ruby
class PostsTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit posts_url
  
    assert_selector "h1", text: "Posts"
    click_on "New Post"
    
    fill_in "Title", with: "Hello"
    click_on "Create Post"
    
    assert_text "Post was successfully created"
  end
end
```

## 4. Assertions (The Cheat Sheet)
- `assert boolean`
- `assert_equal expected, actual`
- `assert_includes collection, item`
- `assert_nil object`
- `assert_difference "User.count", 1 do ... end`
- `assert_redirected_to root_path`

## 5. Mocking (Minitest::Mock)
Use strict mocking only when necessary.

```ruby
mock = Minitest::Mock.new
mock.expect :call, true, [String]

Time.stub :now, Time.at(0) do
  # test code
end
```
