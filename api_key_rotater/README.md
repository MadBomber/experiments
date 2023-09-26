# api_key_rotater

So what happens when you are dealing with an API that is rate limited and you reach the end of a limit?  Do you just wait until the time is up?  Or do you rotate your API_KEY to a new value and retry the API?  Is that cheating?  Could be.  But sometimes a little cheating is good.

Here is what I'm thinking:

```ruby
# You have more than one official API_KEY.  Each
# key is rate limited to something like 5 accesses per
# minute.

API_KEYS = %w[ key1 key2 key3 ]

# Prime the pump just to get started
api_key = API_KEYS.first

retry_count = API_KEYS.size

begin
  access_a_rate_limited_api
rescue RateLimitReached => e
  if retry_count < 0
    raise RateLimitReached, "Consider slowing down or adding another key or spending money and buying better access rights."
  else
    retry_count -= 1
    api_key 		 = API_KEYS.rotate!.first
    retry
  end
end
```


