# Testing Strategies That Reinforce SOLID

Testing patterns that both verify and encourage SOLID compliance.

## SRP: One Reason to Change = One Test File

If a class follows SRP, its tests naturally group into a single concern:

```ruby
# Good: tests for OrderPricer only test pricing
class OrderPricerTest < Minitest::Test
  def test_applies_discount
    pricer = OrderPricer.new(discount: 0.1)
    assert_equal 90.0, pricer.total_for(items_worth(100.0))
  end

  def test_applies_tax
    pricer = OrderPricer.new(tax_rate: 0.08)
    assert_equal 108.0, pricer.total_for(items_worth(100.0))
  end
end
```

**Smell:** If your test file has `describe "pricing"`, `describe "shipping"`,
AND `describe "notifications"` — the class violates SRP.

## OCP: Test New Behavior Without Touching Old Tests

If OCP is followed, adding a new variant means adding a new test file,
not editing existing ones:

```ruby
# Existing tests unchanged:
class CsvExporterTest < Minitest::Test
  def test_exports_csv
    assert_equal "a,b\n1,2\n", CsvExporter.new.export(data)
  end
end

# New format = new test file only:
class PdfExporterTest < Minitest::Test
  def test_exports_pdf
    assert_kind_of String, PdfExporter.new.export(data)
  end
end
```

**Smell:** Adding a new format requires editing `ExporterTest`.

## LSP: Shared Examples Enforce Substitutability

Write contract tests that any conforming implementation must pass:

```ruby
# Minitest shared behavior via module
module TransportContractTests
  def test_responds_to_deliver
    assert_respond_to transport, :deliver
  end

  def test_deliver_accepts_message
    result = transport.deliver(Message.new(body: "test"))
    assert [true, false].include?(result), "deliver must return boolean"
  end

  def test_deliver_does_not_raise_on_valid_input
    transport.deliver(Message.new(body: "test"))
  end
end

class EmailTransportTest < Minitest::Test
  include TransportContractTests
  def transport = EmailTransport.new(config: test_config)
end

class SmsTransportTest < Minitest::Test
  include TransportContractTests
  def transport = SmsTransport.new(config: test_config)
end

class NullTransportTest < Minitest::Test
  include TransportContractTests
  def transport = NullTransport.new
end
```

**Smell:** A subclass test needs to skip or override a parent contract test.

## ISP: Tests Only Exercise Used Methods

If ISP is followed, test setup is minimal — no stubbing unused methods:

```ruby
# Good: dependency only needs #lookup
class GeocoderTest < Minitest::Test
  def test_finds_coordinates
    provider = Minitest::Mock.new
    provider.expect :lookup, { lat: 40.7, lng: -74.0 }, ["New York"]

    geocoder = Geocoder.new(provider: provider)
    assert_equal 40.7, geocoder.latitude_for("New York")

    provider.verify
  end
end
```

**Smell:** Mock setup requires stubbing 10 methods but the test only
calls 2. The interface is too broad.

## DIP: Tests Prove Dependencies Are Swappable

If DIP is followed, tests use fake/null collaborators without any
special setup:

```ruby
class OrderProcessorTest < Minitest::Test
  def setup
    @gateway = FakePaymentGateway.new
    @repo = InMemoryRepository.new
    @notifier = SpyNotifier.new
    @processor = OrderProcessor.new(
      payment_gateway: @gateway,
      repository: @repo,
      notifier: @notifier
    )
  end

  def test_charges_payment
    @processor.process(order)
    assert_equal order.total, @gateway.last_charge
  end

  def test_persists_order
    @processor.process(order)
    assert_equal order, @repo.last_saved
  end

  def test_sends_confirmation
    @processor.process(order)
    assert_equal order, @notifier.last_confirmed
  end
end
```

**Smell:** Tests require `WebMock`, database connections, or ENV vars
to function. The class is coupled to concrete implementations.

## Test Doubles That Enforce Contracts

Use verified doubles to ensure test fakes match real interfaces:

```ruby
# Minitest — hand-rolled verified fake
class FakePaymentGateway
  attr_reader :charges

  def initialize
    @charges = []
  end

  def charge(amount)
    raise ArgumentError, "amount must be positive" unless amount.positive?
    @charges << amount
    true
  end

  def last_charge = @charges.last
end
```

The fake implements the same contract as the real gateway.
If the real interface changes, the fake must change too — keeping
them in sync.

## The SOLID Test Smell Summary

| SOLID Principle | Test Smell When Violated |
|---|---|
| **S** — SRP | Test file has unrelated describe blocks |
| **O** — OCP | Adding a type means editing existing tests |
| **L** — LSP | Subclass tests skip parent contract tests |
| **I** — ISP | Mock setup stubs methods the test never calls |
| **D** — DIP | Tests need network, database, or ENV to run |
