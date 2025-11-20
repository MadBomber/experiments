# Unix System V IPC Experiments

This directory contains Ruby experiments exploring Unix System V Inter-Process Communication (IPC) mechanisms, specifically **Message Queues** and **Shared Memory**.

## Architecture

<svg viewBox="0 0 800 600" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .title { fill: #e0e0e0; font-size: 20px; font-weight: bold; font-family: monospace; }
      .label { fill: #e0e0e0; font-size: 14px; font-family: monospace; }
      .small-label { fill: #b0b0b0; font-size: 12px; font-family: monospace; }
      .process-box { fill: #2a5a8a; stroke: #4a9fd4; stroke-width: 2; }
      .worker-box { fill: #3a6a5a; stroke: #5ac994; stroke-width: 2; }
      .queue-box { fill: #7a4a6a; stroke: #c97aa4; stroke-width: 2; }
      .warning-box { fill: #8a5a2a; stroke: #d49a4a; stroke-width: 2; }
      .arrow { stroke: #4a9fd4; stroke-width: 2; fill: none; marker-end: url(#arrowhead); }
      .warning-arrow { stroke: #d49a4a; stroke-width: 2; fill: none; stroke-dasharray: 5,5; }
    </style>
    <marker id="arrowhead" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto">
      <polygon points="0 0, 10 3, 0 6" fill="#4a9fd4" />
    </marker>
  </defs>

  <!-- Title -->
  <text x="400" y="30" text-anchor="middle" class="title">System V IPC Architecture</text>

  <!-- Master Process -->
  <rect x="300" y="60" width="200" height="80" rx="5" class="process-box"/>
  <text x="400" y="90" text-anchor="middle" class="label">Master Process</text>
  <text x="400" y="110" text-anchor="middle" class="small-label">test_sysvipc.rb</text>
  <text x="400" y="125" text-anchor="middle" class="small-label">test_sysvmq.rb</text>

  <!-- Message Queue -->
  <rect x="300" y="200" width="200" height="80" rx="5" class="queue-box"/>
  <text x="400" y="230" text-anchor="middle" class="label">Message Queue</text>
  <text x="400" y="250" text-anchor="middle" class="small-label">SysVIPC::MessageQueue</text>
  <text x="400" y="265" text-anchor="middle" class="small-label">or SysVMQ</text>

  <!-- Arrows from Master to Queue -->
  <path d="M 400 140 L 400 200" class="arrow"/>
  <text x="420" y="175" class="small-label">send messages</text>

  <!-- Worker Processes -->
  <rect x="100" y="350" width="150" height="70" rx="5" class="worker-box"/>
  <text x="175" y="380" text-anchor="middle" class="label">Worker 1</text>
  <text x="175" y="400" text-anchor="middle" class="small-label">worker.rb</text>

  <rect x="325" y="350" width="150" height="70" rx="5" class="worker-box"/>
  <text x="400" y="380" text-anchor="middle" class="label">Worker 2</text>
  <text x="400" y="400" text-anchor="middle" class="small-label">worker_sysvmq.rb</text>

  <rect x="550" y="350" width="150" height="70" rx="5" class="worker-box"/>
  <text x="625" y="380" text-anchor="middle" class="label">Worker N</text>
  <text x="625" y="400" text-anchor="middle" class="small-label">2-16 workers</text>

  <!-- Arrows from Queue to Workers -->
  <path d="M 350 280 L 200 350" class="arrow"/>
  <path d="M 400 280 L 400 350" class="arrow"/>
  <path d="M 450 280 L 600 350" class="arrow"/>

  <text x="250" y="320" class="small-label">receive</text>
  <text x="410" y="320" class="small-label">receive</text>
  <text x="520" y="320" class="small-label">receive</text>

  <!-- Shared Memory Warning -->
  <rect x="150" y="480" width="500" height="90" rx="5" class="warning-box"/>
  <text x="400" y="505" text-anchor="middle" class="label">Shared Memory (Not Recommended)</text>
  <text x="400" y="525" text-anchor="middle" class="small-label">Ruby's GC prevents reliable use of shared memory</text>
  <text x="400" y="545" text-anchor="middle" class="small-label">Objects cannot be anchored to specific addresses</text>
  <text x="400" y="560" text-anchor="middle" class="small-label">Message Queue approach is preferred</text>

  <!-- Warning connection -->
  <path d="M 400 140 L 400 480" class="warning-arrow"/>
</svg>

## Overview

This directory contains experiments comparing two Ruby gems for System V IPC:

1. **SysVIPC** - Comprehensive IPC gem with message queues and shared memory support
2. **sysvmq** - Simplified message queue implementation

### Key Findings

**Message Queues**: Work reliably for IPC in Ruby. Both `SysVIPC::MessageQueue` and `SysVMQ` provide effective communication between processes.

**Shared Memory**: **Not recommended for Ruby**. Ruby's garbage collector can relocate objects in memory, making it impossible to anchor objects to specific memory addresses required for traditional shared memory IPC patterns. The code includes extensive comments explaining these limitations.

## Files

### Test Programs (Master Processes)

#### `test_sysvipc.rb`
Main test program using the **SysVIPC** gem.

**Features:**
- Creates message queues using file-based key generation (`ftok`)
- Spawns configurable number of worker processes (2-16)
- Demonstrates shared memory limitations (code commented out)
- Uses `cli_helper` for command-line argument handling

**Usage:**
```bash
./test_sysvipc.rb --workers 4
```

**Key Components:**
- Message queue creation: `test_sysvipc.rb:79`
- Shared memory creation (experimental): `test_sysvipc.rb:84`
- Worker spawning: `test_sysvipc.rb:97-100`

#### `test_sysvmq.rb`
Alternative test program using the **sysvmq** gem.

**Features:**
- Simpler API with hardcoded key (`0xDEADC0DE`)
- Creates 1024-byte message queue buffer
- Sends multiple messages per worker
- Waits for queue to drain before completion

**Usage:**
```bash
./test_sysvmq.rb --workers 4
```

**Key Components:**
- Message queue creation: `test_sysvmq.rb:74`
- Message sending: `test_sysvmq.rb:88-90`
- Queue monitoring: `test_sysvmq.rb:92-94`

### Worker Processes

#### `worker.rb`
Worker process for `test_sysvipc.rb`.

**Behavior:**
- Receives message from queue: `worker.rb:31`
- Enters infinite loop crunching random numbers
- Demonstrates multi-core activity (visible in `htop`)
- Must be terminated manually with `killall ruby`

#### `worker_sysvmq.rb`
Worker process for `test_sysvmq.rb`.

**Behavior:**
- Processes messages from queue until empty
- Random delay between messages (0-5 seconds): `worker_sysvmq.rb:19`
- Automatically terminates when queue is drained
- Tracks message count: `worker_sysvmq.rb:14-20`

### Supporting Files

#### `shared_memory.txt`
Reference file used by `SysVIPC.ftok()` to generate consistent IPC keys across processes.

## Dependencies

### Required Gems
```ruby
gem 'SysVIPC'       # For test_sysvipc.rb and worker.rb
gem 'sysvmq'        # For test_sysvmq.rb and worker_sysvmq.rb
gem 'awesome_print' # Pretty printing
gem 'debug_me'      # Debugging output (https://github.com/madbomber/debug_me)
gem 'cli_helper'    # Command-line interface
```

### Installation
```bash
gem install SysVIPC sysvmq awesome_print debug_me cli_helper
```

## Usage Examples

### Basic Usage (2 workers)
```bash
./test_sysvipc.rb
# or
./test_sysvmq.rb
```

### Multiple Workers
```bash
./test_sysvipc.rb --workers 8
./test_sysvmq.rb --workers 8
```

### With Debugging Output
```bash
./test_sysvipc.rb --workers 4 --debug
./test_sysvmq.rb --workers 4 --verbose
```

### Monitoring Multi-Core Activity
```bash
# In one terminal
./test_sysvipc.rb --workers 8

# In another terminal
htop
```

### Cleanup
```bash
# Terminate all worker.rb processes
killall ruby

# Remove IPC resources if needed
ipcs -q  # List message queues
ipcrm -q <msqid>  # Remove specific queue
```

## Technical Details

### Message Queue Key Generation

**SysVIPC approach** (file-based):
```ruby
key = SysVIPC.ftok('shared_memory.txt', 0)
```

**sysvmq approach** (hardcoded):
```ruby
key = 0xDEADC0DE
```

### Process Communication Flow

1. Master process creates message queue
2. Master spawns N worker processes via `Kernel#spawn`
3. Master sends messages to queue
4. Workers receive and process messages
5. Queue drains as workers consume messages

### Shared Memory Limitations in Ruby

From `worker.rb:41-57`:

The shared memory implementation faces fundamental challenges in Ruby:

- Ruby's GC can relocate objects anywhere in memory
- No mechanism to anchor objects to specific addresses
- Traditional C-style offset-based access patterns don't work
- Makes shared memory IPC impractical for Ruby applications

## Configuration

### Valid Workers Range
Both test programs accept 2-16 workers:
```ruby
configatron.valid_workers_range = (2..16)
```

### Message Queue Permissions
- **SysVIPC**: `0600` (owner read/write) or `0660` (group access)
- **sysvmq**: `0666` (all users)

### Buffer Sizes
- **SysVIPC**: 8192 bytes for shared memory
- **sysvmq**: 1024 bytes for message queue

## Monitoring and Debugging

### View IPC Resources
```bash
ipcs -q  # Message queues
ipcs -m  # Shared memory segments
ipcs -s  # Semaphores
ipcs -a  # All IPC resources
```

### Debug Output
Both test programs include extensive debug output showing:
- Process IDs
- IPC keys and handles
- Message content
- Worker status

## Recommendations

1. **Use Message Queues** for IPC in Ruby (not shared memory)
2. **Choose sysvmq** for simpler use cases
3. **Choose SysVIPC** when you need additional IPC features
4. **Monitor workers** with `htop` to verify multi-core utilization
5. **Clean up IPC resources** after testing with `ipcrm`

## Known Issues

1. **worker.rb** processes run indefinitely and must be manually terminated
2. Shared memory code is commented out due to Ruby GC limitations
3. No graceful shutdown mechanism for workers in `test_sysvipc.rb`
4. `test_sysvmq.rb` has commented-out assertions at end of file

## References

- [System V IPC on Wikipedia](https://en.wikipedia.org/wiki/System_V_IPC)
- [SysVIPC gem](https://rubygems.org/gems/SysVIPC)
- [sysvmq gem](https://rubygems.org/gems/sysvmq)
- Unix man pages: `man 2 msgget`, `man 2 shmget`

## License

These are experimental programs by Dewayne VanHoozer (dvanhoozer@gmail.com).
