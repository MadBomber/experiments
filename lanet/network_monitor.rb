# experiments/lanet/network_monitor.rb


require 'lanet'
require 'json'
require 'terminal-notifier' if Gem::Platform.local.os == 'darwin'

class NetworkMonitor
  def initialize(config_file = 'network_config.json')
    @config = JSON.parse(File.read(config_file))
    @scanner = Lanet.scanner
    @sender = Lanet.sender
    @pinger = Lanet.pinger(timeout: 1, count: 3)
    @last_status = {}

    puts "Network Monitor initialized for #{@config['network_name']}"
    puts "Monitoring #{@config['devices'].size} devices on #{@config['network_range']}"
  end

  def scan_network
    puts "\n=== Full Network Scan: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')} ==="
    results = @scanner.scan(@config['network_range'], 1, 32, true)

    # Find unexpected devices
    known_ips = @config['devices'].map { |d| d['ip'] }
    unknown_devices = results.reject { |host| known_ips.include?(host[:ip]) }

    if unknown_devices.any?
      puts "\n⚠️ Unknown devices detected on network:"
      unknown_devices.each do |device|
        puts "  - IP: #{device[:ip]}, Hostname: #{device[:hostname] || 'unknown'}"
      end

      # Alert admin about unknown devices
      message = "#{unknown_devices.size} unknown devices found on network!"
      notify_admin(message)
    end

    results
  end

  def monitor_critical_devices
    puts "\n=== Checking Critical Devices: #{Time.now.strftime('%H:%M:%S')} ==="

    @config['devices'].select { |d| d['critical'] == true }.each do |device|
      result = @pinger.ping_host(device['ip'])
      current_status = result[:status]

      if @last_status[device['ip']] != current_status
        status_changed(device, current_status)
      end

      @last_status[device['ip']] = current_status

      status_text = current_status ? "✅ ONLINE" : "❌ OFFLINE"
      puts "#{device['name']} (#{device['ip']}): #{status_text}"
      puts "  Response time: #{result[:response_time]}ms" if current_status
    end
  end

  def status_changed(device, new_status)
    message = if new_status
                "🟢 #{device['name']} is back ONLINE"
              else
                "🔴 ALERT: #{device['name']} (#{device['ip']}) is DOWN!"
              end

    puts "\n#{message}\n"
    notify_admin(message)

    # Send notification to all network admin devices
    @config['admin_devices'].each do |admin_device|
      @sender.send_to(admin_device['ip'], message)
    end
  end

  def notify_admin(message)
    # Send desktop notification on macOS
    if Gem::Platform.local.os == 'darwin'
      TerminalNotifier.notify(message, title: 'Network Monitor Alert')
    end

    # You could also add SMS, email, or other notification methods here
  end

  def run_continuous_monitoring
    # Initial full network scan
    scan_network

    puts "\nStarting continuous monitoring (press Ctrl+C to stop)..."

    # Set up a listener for incoming alerts
    receiver_thread = Thread.new do
      receiver = Lanet.receiver
      receiver.listen do |message, source_ip|
        puts "\n📨 Message from #{source_ip}: #{message}"
      end
    end

    # Main monitoring loop
    loop do
      monitor_critical_devices

      # Full network scan every hour
      scan_network if Time.now.min == 0

      sleep @config['check_interval']
    end
  rescue Interrupt
    puts "\nMonitoring stopped."
  ensure
    receiver_thread.kill if defined?(receiver_thread) && receiver_thread
  end
end

# Example configuration file (network_config.json):
# {
#   "network_name": "Office Network",
#   "network_range": "192.168.1.0/24",
#   "check_interval": 300,
#   "devices": [
#     {"name": "Router", "ip": "192.168.1.1", "critical": true},
#     {"name": "File Server", "ip": "192.168.1.10", "critical": true},
#     {"name": "Printer", "ip": "192.168.1.20", "critical": false}
#   ],
#   "admin_devices": [
#     {"name": "IT Manager Laptop", "ip": "192.168.1.100"}
#   ]
# }

# Usage:
# monitor = NetworkMonitor.new('network_config.json')
# monitor.run_continuous_monitoring
#
