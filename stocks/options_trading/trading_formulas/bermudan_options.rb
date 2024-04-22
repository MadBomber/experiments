module TradingFormulas
  ##
  # Author:: Matt.Osentoski (matt.osentoski@gmail.com)
  #
  # This module contains formulas based on bermudan equations
  # Converted to Python from "Financial Numerical Recipes in C" by:
  # Bernt Arne Odegaard
  # http://finance.bi.no/~bernt/gcc_prog/index.html
  #
  class BermudanOptions
    
    ##
    # Bermudan Option (Call) using binomial approximations
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price
    # +r+: interest rate
    # +q+: artificial "probability"
    # +sigma+: volatility 
    # +time+: time to maturity 
    # +potential_exercise_times+: Array of potential exercise times. (Ex: [0.25, 0.75] for 1/4 and 3/4 of a year)
    # +steps+: Number of steps in binomial tree
    # *Returns* Option price
    def self.call(s, k, r, q, sigma, time, potential_exercise_times, steps)
      delta_t = time/steps
      r_tmp = Math.exp(r*delta_t)           
      r_inv = 1.0/r_tmp                
      u = Math.exp(sigma*Math.sqrt(delta_t)) 
      uu = u*u
      d = 1.0/u
      p_up = (Math.exp((r-q)*(delta_t))-d)/(u-d)
      p_down = 1.0-p_up
      prices = Array.new(steps+1)
      call_values = Array.new(steps+1)  
      
      potential_exercise_steps = [] # create list of steps at which exercise may happen
      (0..(potential_exercise_times.count)).each do |i|
        t = potential_exercise_times[i].to_f
        if ( (t>0.0) && (t<time) )
          potential_exercise_steps << (t/delta_t).to_i
        end
      end
      prices[0] = s*(d**steps) # fill in the endnodes.
      (1..(steps+1)).each do |i|
        prices[i] = uu*prices[i-1]
      end
      (0..(steps+1)).each do |i|
        call_values[i] = [0.0, (prices[i]-k)].max
      end
      (steps-1).downto(0) do |step|
        check_exercise_this_step = false
        (0..(potential_exercise_steps.count)).each do |j|
          if (step == potential_exercise_steps[j])
            check_exercise_this_step = true
          end
        end   
        (0..(steps+1)).each do |i|           
          call_values[i] = (p_up*call_values[i+1].to_f+p_down*call_values[i].to_f)*r_inv
          prices[i] = d*prices[i+1].to_f
          if (check_exercise_this_step)
            call_values[i] = [call_values[i].to_f,prices[i].to_f-k].max
          end
        end          
      end            
      return call_values[0]   
    end
    
    
    ##
    # Bermudan Option (Put) using binomial approximations
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price
    # +r+: interest rate
    # +q+: artificial "probability"
    # +sigma+: volatility 
    # +time+: time to maturity 
    # +potential_exercise_times+: Array of potential exercise times. (Ex: [0.25, 0.75] for 1/4 and 3/4 of a year)
    # +steps+: Number of steps in binomial tree
    # *Returns* Option price
    def self.put(s, k, r, q, sigma, time, potential_exercise_times, steps)
      delta_t=time/steps
      r_tmp = Math.exp(r*delta_t)       
      r_inv = 1.0/r_tmp                
      u = Math.exp(sigma*Math.sqrt(delta_t))
      uu = u*u
      d = 1.0/u
      p_up = (Math.exp((r-q)*delta_t)-d)/(u-d)
      p_down = 1.0-p_up 
      prices = Array.new(steps+1)
      put_values = Array.new(steps+1)
  
      potential_exercise_steps = [] # create list of steps at which exercise may happen
      (0..(potential_exercise_times.count)).each do |i|
        t = potential_exercise_times[i].to_f
        if ( (t>0.0) && (t<time) )
          potential_exercise_steps << (t/delta_t).to_i
        end
      end
      prices[0] = s*(d**steps) # fill in the endnodes.
      (1..(steps+1)).each do |i|
        prices[i] = uu*prices[i-1]
      end
      (0..(steps+1)).each do |i|
        put_values[i] = [0.0, (k-prices[i])].max # put payoffs at maturity
      end
      (steps-1).downto(0) do |step|
        check_exercise_this_step = false
        (0..(potential_exercise_steps.count)).each do |j|
          if (step == potential_exercise_steps[j])
            check_exercise_this_step = true
          end
        end
        (0..(steps+1)).each do |i|
          put_values[i] = (p_up*put_values[i+1].to_f+p_down*put_values[i].to_f)*r_inv
          prices[i] = d*prices[i+1].to_f 
          if (check_exercise_this_step)
            put_values[i] = [put_values[i].to_f,k-prices[i].to_f].max
          end
        end
      end      
      return put_values[0]
    end
    
  end
end