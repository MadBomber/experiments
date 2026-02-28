# Growth Engineering Skills

> **Concepts:** A/B Testing, Feature Flags, Phased Rollouts.
> **Gems:** `flipper`, `split`, `unleash`.

## 1. Feature Flags (Flipper)
Decouple deployment from release. Push code to production, but keep it hidden.

### Setup (Rails)
Use the `flipper` gem with the ActiveRecord adapter.

```ruby
# Gemfile
gem "flipper"
gem "flipper-active_record"
```

### Usage
```ruby
# Check flag
if Flipper.enabled?(:new_checkout, current_user)
  render "checkout/v2"
else
  render "checkout/v1"
end

# Enable for percentage of actors
Flipper.enable_percentage_of_actors(:new_checkout, 10)
```

## 2. A/B Testing (Split Testing)
Scientific validation of features.

### Designing a Test
1.  **Hypothesis:** "Changing the button color to green will increase signups."
2.  **Metrics:** Conversion Rate (Signups / Visitors).
3.  **Sample Size:** Calculate needed traffic for statistical significance.

### Implementation (Split Gem)
```ruby
# Controller
def index
  @ab_test_result = ab_test(:signup_button_color, "blue", "green")
end

# View
<%= link_to "Sign Up", signup_path, class: "btn btn-#{@ab_test_result}" %>

# Tracking Conversion
finished(:signup_button_color)
```

## 3. Rollout Strategy
1.  **Internal:** Enable for admins/employees (`Flipper.enable_group(:new_feature, :admins)`).
2.  **Canary:** Enable for 1% of users. Monitor errors (AppSignal).
3.  **Beta:** Enable for opt-in beta users.
4.  **GA (General Availability):** Enable for 100%. Remove the flag cleanup code.
