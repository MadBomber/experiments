# State Machines (AASM)

> **Gem:** `aasm`
> **Use Case:** Managing complex lifecycle states (Orders, Payments, Posts).

## 1. Basic Setup

```ruby
class Order < ApplicationRecord
  include AASM

  aasm column: :status do
    state :pending, initial: true
    state :paid
    state :shipped
    state :cancelled

    event :pay do
      transitions from: :pending, to: :paid
      after { OrderMailer.receipt(self).deliver_later }
    end

    event :ship do
      transitions from: :paid, to: :shipped, guard: :address_present?
    end
  end

  def address_present?
    address.present?
  end
end
```

## 2. Best Practices
- **Guards:** Use `guard` to prevent transitions (e.g., preventing shipping without an address).
- **Callbacks:** Use `after` or `before` for side effects (emails, inventory), but prefer calling them via an Interaction if complex.
- **Scopes:** AASM gives you `Order.pending`, `Order.paid` automatically.

## 3. Testing
Test transitions and side effects.

```ruby
it "transitions from pending to paid" do
  expect { order.pay! }.to change(order, :status).from("pending").to("paid")
end

it "does not allow shipping if address missing" do
  order.address = nil
  expect { order.ship! }.to raise_error(AASM::InvalidTransition)
end
```
