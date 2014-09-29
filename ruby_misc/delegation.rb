#!/usr/bin/ruby -w 
# delegation.rb 
class CEO 
  def CEO.new_vision 
    Manager.implement_vision 
  end 
end 

class Manager 
  def Manager.implement_vision 
    Engineer.do_work 
  end 
end 

class Engineer 
  def Engineer.do_work 
    puts 'How did I get here?' 
    first = true 
    caller.each do |c| 
      puts %{#{(first ? 'I' : ' which')} was called by "#{c}"} 
      first = false 
    end 
    puts "TDV said that I was really just called by #{caller.last}"
  end 
end 
 
CEO.new_vision 
