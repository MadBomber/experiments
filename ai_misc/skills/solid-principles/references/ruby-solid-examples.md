# Ruby SOLID Examples from Real-World Gems

Extended examples showing how well-known Ruby gems apply SOLID principles.

## SRP in Practice

### Devise — Modular Authentication

Devise doesn't put everything in one `Authenticatable` module. Each
concern is a separate module the user opts into:

```ruby
class User < ApplicationRecord
  devise :database_authenticatable,  # password handling
         :registerable,              # sign-up
         :recoverable,               # password reset
         :rememberable,              # cookie remember-me
         :validatable                # email/password validations
end
```

Each module has a single responsibility. Adding `:trackable` doesn't
change how `:recoverable` works.

### Sidekiq — Worker vs Queue vs Middleware

Sidekiq separates job definition, queue management, and middleware
processing into distinct classes. A worker only defines `perform`.
Queue selection, retry logic, and logging are separate concerns.

---

## OCP in Practice

### ActiveRecord Callbacks — Hook Points Without Modification

ActiveRecord is closed for modification but open for extension via callbacks:

```ruby
class Order < ApplicationRecord
  after_create :send_notification
  after_update :sync_inventory

  private

  def send_notification = OrderNotifier.new(self).deliver
  def sync_inventory = InventorySync.call(self)
end
```

Adding behavior doesn't require editing ActiveRecord internals.

### Faraday — Middleware Stack

Faraday's middleware architecture is pure OCP:

```ruby
conn = Faraday.new do |f|
  f.request  :json
  f.response :logger
  f.response :json
  f.adapter  :net_http
end
```

Adding authentication, caching, or retry logic means adding a
middleware — never editing existing ones.

---

## LSP in Practice

### IO and StringIO

`StringIO` is a perfect LSP substitute for `IO`:

```ruby
def process(io)
  io.each_line { |line| parse(line) }
end

# Both work identically:
process(File.open("data.csv"))
process(StringIO.new("col1,col2\nval1,val2\n"))
```

### ActiveRecord and NullObject Pattern

```ruby
class GuestUser
  def name = "Guest"
  def admin? = false
  def persisted? = false
end

# Substitutes for User anywhere that reads name/admin?/persisted?
current_user = logged_in? ? User.find(session[:id]) : GuestUser.new
```

---

## ISP in Practice

### Enumerable — Focused Interface Inclusion

Ruby's `Enumerable` requires only `each` and optionally `<=>`:

```ruby
class WordList
  include Enumerable

  def initialize(words) = @words = words
  def each(&block) = @words.each(&block)
end

# Gets map, select, reject, sort, min, max, etc.
# But only implements ONE method
```

### Comparable — Minimal Contract

```ruby
class Temperature
  include Comparable

  attr_reader :degrees

  def initialize(degrees) = @degrees = degrees
  def <=>(other) = degrees <=> other.degrees
end

# Gets <, <=, >, >=, between?, clamp for free
```

---

## DIP in Practice

### Rails Logger

Rails doesn't hard-code a logger implementation:

```ruby
# config/application.rb
config.logger = Logger.new($stdout)
# or
config.logger = Syslog::Logger.new("myapp")
# or
config.logger = ActiveSupport::TaggedLogging.new(Logger.new("log/app.log"))
```

All Rails code depends on the logger abstraction, not a specific logger.

### Searchkick — Configurable Client

```ruby
# Default: auto-detects Elasticsearch or OpenSearch
Searchkick.client

# Override with any compatible client:
Searchkick.client = OpenSearch::Client.new(url: "http://localhost:9200")
```

High-level search logic never references a specific client class.

### Strong Migrations — Adapter Pattern

```ruby
# Detects database automatically, injects the right adapter
def adapter
  case connection.adapter_name
  when /postg/i   then Adapters::PostgreSQLAdapter.new(self)
  when /mysql/i   then Adapters::MySQLAdapter.new(self)
  else                 Adapters::AbstractAdapter.new(self)
  end
end
```

Migration checks depend on the abstract adapter interface.
Database-specific SQL is encapsulated in each adapter.

---

## Anti-Pattern Gallery

### SRP Violation: God Object

```ruby
class User < ApplicationRecord
  # Authentication
  def authenticate(password) = ...
  def generate_token = ...

  # Authorization
  def can?(action, resource) = ...
  def admin? = ...

  # Profile
  def full_name = ...
  def avatar_url = ...

  # Billing
  def charge(amount) = ...
  def update_subscription(plan) = ...

  # Notifications
  def notify(message) = ...
  def notification_preferences = ...
end
```

Fix: Extract `Authentication`, `Authorization`, `Billing`,
`Notifications` into separate objects or concerns.

### OCP Violation: Type Checking

```ruby
def calculate_shipping(item)
  if item.is_a?(Book)
    item.weight * 0.5
  elsif item.is_a?(Electronics)
    item.weight * 1.2 + 5.00
  elsif item.is_a?(Clothing)
    3.99
  end
end
```

Fix: Each item class implements `#shipping_cost`.

### DIP Violation: Hard-Coded Dependencies

```ruby
class ReportGenerator
  def generate
    data = PostgresQuery.execute("SELECT ...")   # welded to Postgres
    csv = CSV.generate { |c| data.each { |r| c << r } }
    S3Client.upload("reports/#{Date.today}.csv", csv)  # welded to S3
  end
end
```

Fix: Inject `data_source`, `formatter`, and `storage` as dependencies.
