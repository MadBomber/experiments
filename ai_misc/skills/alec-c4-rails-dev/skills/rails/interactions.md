# ActiveInteraction Skills

> **Philosophy:** Strict contracts, type safety, and composition over "Service Objects".
> **Gem:** `active_interaction`

## 1. Why Interactions?
Unlike plain Service Objects, Interactions provide:
- **Inputs:** Typed arguments.
- **Validations:** Active Model validations on inputs.
- **Outcome:** Standard `valid?` / `result` interface.

## 2. Basic Structure

```ruby
module Users
  class Create < ActiveInteraction::Base
    # Inputs
    string :email
    string :name
    string :password, default: nil
    boolean :notify, default: true

    # Validations
    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

    def execute
      user = User.create!(
        email: email,
        name: name,
        password: password || SecureRandom.hex(10)
      )

      if notify
        UserMailer.welcome(user).deliver_later
      end

      user # This becomes the result
    end
  end
end
```

## 3. Advanced Features

### Composition
Use `compose` to call other interactions. Errors bubble up automatically.

```ruby
def execute
  user = compose(Users::Create, email: email, name: name)
  compose(Billing::CreateAccount, user: user)
  user
end
```

### Input Types
- `object :user, class: User`
- `array :tags`
- `hash :settings`
- `date :birthday`
- `file :attachment`

## 4. Testing Interactions
Test inputs and outcomes, not internal state.

```ruby
RSpec.describe Users::Create do
  describe ".run" do
    let(:valid_inputs) { { email: "test@example.com", name: "Test" } }

    it "creates a user" do
      outcome = described_class.run(valid_inputs)
      expect(outcome).to be_valid
      expect(outcome.result).to be_a(User)
    end

    it "fails with invalid email" do
      outcome = described_class.run(valid_inputs.merge(email: "bad"))
      expect(outcome).to be_invalid
      expect(outcome.errors[:email]).to include("is invalid")
    end
  end
end
```
