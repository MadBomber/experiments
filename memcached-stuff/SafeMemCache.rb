#
# A Safe Wrapper around memcache client that will not raise exceptions
#
class SafeMemCache  < MemCache
 
 def decr(key, amount = 1)
 super
 rescue MemCacheError => e
 nil
 end
 
 def get(key, raw = false)
 super
 rescue MemCacheError => e
 nil
 end
 
 def fetch(key, expiry = 0, raw = false)
 super
 rescue MemCacheError => e
 nil
 end
 
 def get_multi(*keys)
 super
 rescue MemCacheError => e
 nil
 end
 
 def incr(key, amount = 1)
 super
 rescue MemCacheError => e
 nil
 end
 
 def set(key, value, expiry = 0, raw = false)
 super
 rescue MemCacheError => e
 nil
 end
 
 def cas(key, expiry=0, raw=false)
 super
 rescue MemCacheError => e
 nil
 end
 
 def add(key, value, expiry = 0, raw = false)
 super
 rescue MemCacheError => e
 nil
 end
 
 def replace(key, value, expiry = 0, raw = false)
 super
 rescue MemCacheError => e
 nil
 end
 
 def append(key, value)
 super
 rescue MemCacheError => e
 nil
 end
 
 def prepend(key, value)
 super
 rescue MemCacheError => e
 nil
 end
 
 def delete(key, expiry = 0)
 super
 rescue MemCacheError => e
 nil
 end
 
 def flush_all(delay=0)
 super
 rescue MemCacheError => e
 nil
 end
 
 def reset
 super
 rescue MemCacheError => e
 nil
 end
 
 def stats
 super
 rescue MemCacheError => e
 nil
 end
 
end