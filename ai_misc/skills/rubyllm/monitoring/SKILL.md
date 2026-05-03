---
name: rubyllm/monitoring
version: 0.3.2
description: |
  Rails engine for RubyLLM monitoring dashboards and alerts. Use this skill when you need visibility into LLM costs, throughput, response times, and error rates. Captures events from ruby_llm-instrumentation.
---

# RubyLLM::Monitoring v0.3.2

**Monitoring dashboards and alerts for RubyLLM**

Rails engine providing dashboards for cost, throughput, response time, and error aggregations. Supports configurable alerts via email, Slack, etc.

**Gem Version:** 0.3.2  
**GitHub:** https://github.com/sinaptia/ruby_llm-monitoring

## Installation

```bash
gem 'ruby_llm-monitoring'
```

Requires `ruby_llm-instrumentation` (automatically included).

## Setup

```bash
bin/rails ruby_llm_monitoring:install
bin/rails db:migrate
```

### Mount Engine

```ruby
# config/routes.rb
mount RubyLLM::Monitoring::Engine, at: '/ruby_llm_monitoring'
```

Visit `/ruby_llm_monitoring` for dashboards.

## Dashboards

### Cost Tracking

- Daily/weekly/monthly cost breakdown
- Cost by provider
- Cost by model
- Cost by feature/user (with metadata)

### Throughput Metrics

- Requests per minute/hour/day
- Tokens per request
- Concurrent requests

### Response Time

- P50, P95, P99 latency
- Latency by provider/model
- Streaming vs non-streaming

### Error Rates

- Error rate over time
- Errors by type
- Errors by provider/model

## Alerts

### Configuration

```ruby
# config/initializers/ruby_llm_monitoring.rb
RubyLLM::Monitoring.configure do |config|
  # Alert channels
  config.alert_channels = [:email, :slack]
  
  config.slack_webhook_url = ENV['SLACK_WEBHOOK_URL']
  config.alert_email = 'alerts@example.com'
  
  # Alert rules
  config.alerts << {
    name: 'High Error Rate',
    metric: :error_rate,
    threshold: 0.05,  # 5%
    channel: :slack,
    window: 5.minutes
  }
  
  config.alerts << {
    name: 'Daily Cost Limit',
    metric: :daily_cost,
    threshold: 100.00,  # $100
    channel: :email
  }
  
  config.alerts << {
    name: 'High Latency',
    metric: :p95_latency,
    threshold: 30,  # 30 seconds
    channel: :slack,
    window: 10.minutes
  }
end
```

### Alert Channels

#### Slack

```ruby
config.slack_webhook_url = ENV['SLACK_WEBHOOK_URL']

# Or per-alert
config.alerts << {
  name: 'Error Spike',
  metric: :error_rate,
  threshold: 0.1,
  channel: :slack
}
```

#### Email

```ruby
config.alert_email = 'alerts@example.com'
config.smtp_settings = {
  address: 'smtp.example.com',
  port: 587,
  user_name: ENV['SMTP_USER'],
  password: ENV['SMTP_PASSWORD']
}
```

#### Custom Channels

```ruby
RubyLLM::Monitoring.register_channel(:pagerduty) do |alert|
  PagerDuty.trigger(
    service_key: ENV['PAGERDUTY_KEY'],
    description: alert.message,
    severity: alert.severity
  )
end

config.alerts << {
  name: 'Critical Error',
  metric: :error_rate,
  threshold: 0.5,
  channel: :pagerduty
}
```

## Metrics API

```ruby
# Get metrics programmatically
RubyLLM::Monitoring.metrics(
  metric: :cost,
  start: 1.day.ago,
  finish: Time.current,
  group_by: :provider
)

# Available metrics
:cost
:input_tokens
:output_tokens
:error_rate
:latency_p50
:latency_p95
:latency_p99
:requests_count
```

## Custom Dashboards

```ruby
# app/dashboards/custom_llm_dashboard.rb
class CustomLlmDashboard < RubyLLM::Monitoring::Dashboard
  title "Custom LLM Metrics"
  
  panel "Cost by Feature" do
    chart :cost, group_by: ->(e) { e.metadata&.dig(:feature) }
  end
  
  panel "User Activity" do
    chart :requests_count, group_by: ->(e) { e.metadata&.dig(:user_id) }
  end
end
```

## Data Retention

```ruby
# config/initializers/ruby_llm_monitoring.rb
RubyLLM::Monitoring.configure do |config|
  config.retention_days = 30  # Default: 30 days
  
  # Archive old data
  config.archive_enabled = true
  config.archive_path = Rails.root.join('db', 'llm_archives')
end
```

## Multi-Tenant Tracking

```ruby
# Include tenant in metadata
class ApplicationController < ActionController::Base
  around_action :instrument_llm_with_tenant

  private

  def instrument_llm_with_tenant
    RubyLLM::Instrumentation.with(tenant_id: current_tenant.id) do
      yield
    end
  end
end

# Dashboard filters by tenant
RubyLLM::Monitoring.metrics(
  metric: :cost,
  filter: { tenant_id: current_tenant.id }
)
```

## Export Data

```ruby
# Export to CSV
RubyLLM::Monitoring.export(
  format: :csv,
  start: 1.week.ago,
  finish: Time.current,
  metrics: [:cost, :requests_count, :error_rate]
)

# Export to JSON
RubyLLM::Monitoring.export(
  format: :json,
  start: 1.day.ago,
  group_by: :provider
)
```

## See Also

- **Main RubyLLM**: [rubyllm](../SKILL.md)
- **Instrumentation**: [rubyllm/instrumentation](../instrumentation/SKILL.md)
