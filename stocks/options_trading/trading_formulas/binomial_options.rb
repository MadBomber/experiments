module TradingFormulas
  ##
  # Author:: Matt.Osentoski (matt.osentoski@gmail.com)
  #
  # This module contains formulas based on binomial equations
  # Converted to Python from "Financial Numerical Recipes in C" by:
  # Bernt Arne Odegaard
  # http://finance.bi.no/~bernt/gcc_prog/index.html
  #
  class BinomialOptions
    
    ##
    # American Option (Call) using binomial approximations
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price,
    # +r+: interest rate
    # +sigma+: volatility 
    # +t+: time to maturity 
    # +steps+: Number of steps in binomial tree
    # *Rreturns* Option price
    #
    def self.call(s, k, r, sigma, t, steps)
      r_tmp = Math.exp(r*(t/steps))       
      r_inv = 1.0/r_tmp                 
      u = Math.exp(sigma*Math.sqrt(t/steps)) 
      d = 1.0/u
      p_up = (r_tmp-d)/(u-d)
      p_down = 1.0-p_up
      prices = Array.new(steps+1) # price of underlying
      prices[0] = s*(d**steps) # fill in the endnodes.
      uu = u*u
      
      (1..(steps+1)).each do |i|
        prices[i] = uu*prices[i-1]
      end 
      call_values = Array.new(steps+1) # value of corresponding call
      (0..(steps+1)).each do |i|
          call_values[i] = [0.0, (prices[i]-k)].max # call payoffs at maturity
      end
      
      (steps-1).downto(0) do |step|
        (0..(step+1)).each do |i|
          call_values[i] = (p_up*call_values[i+1]+p_down*call_values[i])*r_inv
          prices[i] = d*prices[i+1]
          call_values[i] = [call_values[i],prices[i]-k].max # check for exercise
        end
      end
      return call_values[0]
    end
    
    ##
    # American Option (Put) using binomial approximations
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price,
    # +r+: interest rate
    # +sigma+: volatility 
    # +t+: time to maturity 
    # +steps+: Number of steps in binomial tree
    # *Returns*: Option price
    #
    def self.put(s, k, r, sigma, t, steps)
      r_tmp = Math.exp(r*(t/steps)) # interest rate for each step
      r_inv = 1.0/r_tmp # inverse of interest rate
      u = Math.exp(sigma*Math.sqrt(t/steps)) # up movement
      uu = u*u
      d = 1.0/u
      p_up = (r_tmp-d)/(u-d)
      p_down = 1.0-p_up
      prices = Array.new(steps+1) # price of underlying
      prices[0] = s*(d**steps) 
      
      (1..(steps+1)).each do |i|
          prices[i] = uu*prices[i-1]
      end
      
      put_values = Array.new(steps+1) # value of corresponding put
  
      (0..(steps+1)).each do |i|
          put_values[i] = [0.0, (k-prices[i])].max # put payoffs at maturity
      end
      
      (steps-1).downto(0) do |step|
        (0..(steps+1)).each do |i|
            put_values[i] = (p_up*put_values[i+1].to_f+p_down*put_values[i])*r_inv
            prices[i] = d*prices[i+1].to_f
            put_values[i] = [put_values[i],(k-prices[i])].max # check for exercise
        end
      end
      return put_values[0]
    end
    
    ##
    # Delta of an American Option (Call) using binomial approximations
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price,
    # +r+: interest rate
    # +sigma+: volatility 
    # +t+: time to maturity 
    # +steps+: Number of steps in binomial tree
    # *Returns* Delta of the option
    def self.delta_call(s, k, r, sigma, t, steps)
      r_tmp = Math.exp(r*(t/steps))
      r_inv = 1.0/r_tmp
      u = Math.exp(sigma*Math.sqrt(t/steps))
      d = 1.0/u
      uu= u*u
      pUp   = (r_tmp-d)/(u-d)
      pDown = 1.0 - pUp
      
      prices = Array.new(steps+1)
      prices[0] = s*(d**steps)
      
      (1..(steps+1)).each do |i|
        prices[i] = uu*prices[i-1].to_f
      end
  
      call_values = Array.new(steps+1)
  
      (0..(steps+1)).each do |i|
        call_values[i] = [0.0, (prices[i]-k)].max
      end
  
      (steps-1).downto(1) do |step|
        (0..(steps+1)).each do |i|
          prices[i] = d*prices[i+1].to_f
          call_values[i] = (pDown*call_values[i].to_f+pUp*call_values[i+1].to_f)*r_inv
          call_values[i] = [call_values[i], (prices[i]-k)].max # check for exercise
        end
      end
      delta = (call_values[1]-call_values[0])/(s*u-s*d)
      return delta
    end
    
    ##
    # Delta of an American Option (Put) using binomial approximations
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price,
    # +r+: interest rate
    # +sigma+: volatility 
    # +t+: time to maturity 
    # +steps+: Number of steps in binomial tree
    # *Returns* Delta of the option
    def self.delta_put(s, k, r, sigma, t, steps)
      prices = Array.new(steps+1)
      put_values = Array.new(steps+1)
      r_tmp = Math.exp(r*(t/steps))
      r_inv = 1.0/r_tmp
      u = Math.exp(sigma*Math.sqrt(t/steps))
      d = 1.0/u
      uu= u*u
      pUp   = (r_tmp-d)/(u-d)
      pDown = 1.0 - pUp
      prices[0] = s*(d**steps)
     
      (1..(steps+1)).each do |i|
        prices[i] = uu*prices[i-1].to_f
      end
  
      (0..(steps+1)).each do |i|
        put_values[i] = [0.0, (k - prices[i])].max
      end
  
      (steps-1).downto(1) do |step|
        (0..(steps+1)).each do |i|
          prices[i] = d*prices[i+1].to_f
          put_values[i] = (pDown*put_values[i].to_f+pUp*put_values[i+1].to_f)*r_inv
          put_values[i] = [put_values[i], (k-prices[i])].max # check for exercise
        end
      end
      delta = (put_values[1]-put_values[0])/(s*u-s*d)
      return delta
    end
    
    ##
    # Calculate partial derivatives for an American Option (Call) using 
    # binomial approximations.
    # (NOTE: Originally, this method used argument pointer references as a
    # way of returning the partial derivatives in C++. I've removed these 
    # references from the method signature and chose to return a tuple instead.)
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price,
    # +r+: interest rate
    # +sigma+: volatility 
    # +time+: time to maturity 
    # +steps+: Number of steps in binomial tree
    # *Returns* Tuple of partial derivatives: (Delta, Gamma, Theta, Vega, Rho)
    # delta: partial wrt S
    # gamma: second partial wrt S
    # theta: partial wrt time
    # vega: partial wrt sigma
    # rho: partial wrt r
    def self.partials_call(s, k, r, sigma, time, steps)
      prices = Array.new(steps+1)
      call_values = Array.new(steps+1)
      delta_t =(time/steps)
      r_tmp = Math.exp(r*delta_t)
      r_inv = 1.0/r_tmp
      u = Math.exp(sigma*Math.sqrt(delta_t))
      d = 1.0/u
      uu= u*u
      pUp   = (r_tmp-d)/(u-d)
      pDown = 1.0 - pUp
      prices[0] = s*(d**steps)
      
      (1..(steps+1)).each do |i|
        prices[i] = uu*prices[i-1].to_f
      end
  
      (0..(steps+1)).each do |i|
        call_values[i] = [0.0, (prices[i]-k)].max
      end
      
      (steps-1).downto(2) do |step|
        (0..(steps+1)).each do |i|
          prices[i] = d*prices[i+1].to_f
          call_values[i] = (pDown*call_values[i].to_f+pUp*call_values[i+1].to_f)*r_inv
          call_values[i] = [call_values[i], (prices[i]-k)].max # check for exercise
        end
      end
      
      f22 = call_values[2]
      f21 = call_values[1]
      f20 = call_values[0]
      (0..1).each do |i|
        prices[i] = d*prices[i+1]
        call_values[i] = (pDown*call_values[i]+pUp*call_values[i+1])*r_inv
        call_values[i] = [call_values[i], (prices[i]-k)].max # check for exercise 
      end
      
      f11 = call_values[1]
      f10 = call_values[0]
      prices[0] = d*prices[1]
      call_values[0] = (pDown*call_values[0]+pUp*call_values[1])*r_inv
      call_values[0] = [call_values[0], (s-k)].max # check for exercise on first date
      f00 = call_values[0]
      delta = (f11-f10)/(s*u-s*d)
      h = 0.5 * s * ( uu - d*d)
      gamma = ( (f22-f21)/(s*(uu-1)) - (f21-f20)/(s*(1-d*d)) ) / h 
      theta = (f21-f00) / (2*delta_t)
      diff = 0.02
      tmp_sigma = sigma+diff
      tmp_prices = TradingFormulas::BinomialOptions.call(s,k,r,tmp_sigma,time,steps)
      vega = (tmp_prices-f00)/diff
      diff = 0.05
      tmp_r = r+diff
      tmp_prices = TradingFormulas::BinomialOptions.call(s,k,tmp_r,sigma,time,steps)
      rho = (tmp_prices-f00)/diff
      return delta, gamma, theta, vega, rho
    end 
    
    ##
    # Calculate partial derivatives for an American Option (Put) using 
    # binomial approximations.
    # (NOTE: Originally, this method used argument pointer references as a
    # way of returning the partial derivatives in C++. I've removed these 
    # references from the method signature and chose to return a tuple instead.)
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price,
    # +r+: interest rate
    # +sigma+: volatility 
    # +time+: time to maturity 
    # +steps+: Number of steps in binomial tree
    # *Returns*: Tuple of partial derivatives: (Delta, Gamma, Theta, Vega, Rho)
    # delta: partial wrt S
    # gamma: second partial wrt S
    # theta: partial wrt time
    # vega: partial wrt sigma
    # rho: partial wrt r
    def self.partials_put(s, k, r, sigma, time, steps)
      prices = Array.new(steps+1)
      put_values = Array.new(steps+1)
      delta_t =(time/steps)
      r_tmp = Math.exp(r*delta_t)
      r_inv = 1.0/r_tmp
      u = Math.exp(sigma*Math.sqrt(delta_t))
      d = 1.0/u
      uu= u*u
      pUp   = (r_tmp-d)/(u-d)
      pDown = 1.0 - pUp
      prices[0] = s*(d**steps)

      (1..(steps+1)).each do |i|
        prices[i] = uu*prices[i-1].to_f
      end
      
      (0..(steps+1)).each do |i|
        put_values[i] = [0.0, (k-prices[i])].max
      end
      
      (steps-1).downto(2) do |step|
        (0..(steps+1)).each do |i|
          prices[i] = d*prices[i+1].to_f
          put_values[i] = (pDown*put_values[i].to_f+pUp*put_values[i+1].to_f)*r_inv
          put_values[i] = [put_values[i], k-prices[i]].max # check for exercise
        end
      end
      
      f22 = put_values[2]
      f21 = put_values[1]
      f20 = put_values[0]
      i_tmp = 0
      (0..1).each do |i|
        prices[i] = d*prices[i+1]
        put_values[i] = (pDown*put_values[i]+pUp*put_values[i+1])*r_inv
        put_values[i] = [put_values[i], k-prices[i]].max # check for exercise
        i_tmp = i
      end
      
      f11 = put_values[1]
      f10 = put_values[0]
      prices[0] = d*prices[1]
      put_values[0] = (pDown*put_values[0]+pUp*put_values[1])*r_inv
      put_values[0] = [put_values[0], k-prices[i_tmp]].max # check for exercise
      f00 = put_values[0]
      delta = (f11-f10)/(s*(u-d))
      h = 0.5 * s *( uu - d*d)
      gamma = ( (f22-f21)/(s*(uu-1.0)) - (f21-f20)/(s*(1.0-d*d)) ) / h
      theta = (f21-f00) / (2*delta_t)
      diff = 0.02
      tmp_sigma = sigma+diff
      tmp_prices = TradingFormulas::BinomialOptions.put(s,k,r,tmp_sigma,time,steps)
      vega = (tmp_prices-f00)/diff
      diff = 0.05
      tmp_r = r+diff
      tmp_prices = TradingFormulas::BinomialOptions.put(s,k,tmp_r,sigma,time,steps)
      rho = (tmp_prices-f00)/diff
      return delta, gamma, theta, vega, rho
    end
    
    ##
    # American Option (Call) for dividends with specific (discrete) dollar amounts 
    # using binomial approximations
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price,
    # +r+: interest rate
    # +sigma+: volatility 
    # +t+: time to maturity 
    # +steps+: Number of steps in binomial tree
    # +dividend_times+: Array of dividend times. (Ex: [0.25, 0.75] for 1/4 and 3/4 of a year)
    # +dividend_amounts+: Array of dividend amounts for the 'dividend_times'
    # *Returns* Option price
    def self.discrete_dividends_call(s, k, r, sigma, t, steps, dividend_times, dividend_amounts)
      no_dividends = dividend_times.count
      if (no_dividends==0)
        return TradingFormulas::BinomialOptions.call(s,k,r,sigma,t,steps) # just do regular
      end
      steps_before_dividend = (dividend_times[0]/t*steps).to_i
      r_tmp = Math.exp(r*(t/steps))
      r_inv = 1.0/r_tmp
      u = Math.exp(sigma*Math.sqrt(t/steps))
      d = 1.0/u
      pUp = (r_tmp-d)/(u-d)
      pDown = 1.0 - pUp
      dividend_amount = dividend_amounts[0]
      tmp_dividend_times = Array.new(no_dividends-1) # temporaries with 
      tmp_dividend_amounts = Array.new(no_dividends-1) # one less dividend 
      (0..(no_dividends-2)).each do |i|
        tmp_dividend_amounts[i] = dividend_amounts[i+1].to_f
        tmp_dividend_times[i]   = dividend_times[i+1].to_f - dividend_times[0].to_f
      end    
      prices = Array.new(steps_before_dividend+1)
      call_values = Array.new(steps_before_dividend+1)
      prices[0] = s*(d**steps_before_dividend)
      
      (1..(steps_before_dividend+1)).each do |i|
        prices[i] = u*u*prices[i-1].to_f
      end
  
      (0..(steps_before_dividend+1)).each do |i|
        value_alive = TradingFormulas::BinomialOptions.discrete_dividends_call(prices[i]-dividend_amount,k, r, sigma,
          t-dividend_times[0], # time after first dividend
          steps-steps_before_dividend, 
          tmp_dividend_times,
          tmp_dividend_amounts)
        call_values[i] = [value_alive,(prices[i]-k)].max # compare to exercising now
      end
      
      (steps_before_dividend-1).downto(0) do |step|
        (0..(steps+1)).each do |i|
          prices[i] = d*prices[i+1].to_f
          call_values[i] = (pDown*call_values[i].to_f+pUp*call_values[i+1].to_f)*r_inv
          call_values[i] = [call_values[i], prices[i]-k].max
        end
      end
      return call_values[0]  
    end
    
    ##
    # American Option (Put) for dividends with specific (discrete) dollar amounts 
    # using binomial approximations
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price,
    # +r+: interest rate
    # +sigma+: volatility 
    # +t+: time to maturity 
    # +steps+: Number of steps in binomial tree
    # +dividend_times+: Array of dividend times. (Ex: [0.25, 0.75] for 1/4 and 3/4 of a year)
    # +dividend_amounts+: Array of dividend amounts for the 'dividend_times'
    # *Returns* Option price
    def self.discrete_dividends_put(s, k, r, sigma, t, steps, dividend_times, dividend_amounts)
      # given an amount of dividend, the binomial tree does not recombine, have to 
      # start a new tree at each ex-dividend date.
      # do this recursively, at each ex dividend date, at each step, put the 
      # binomial formula starting at that point to calculate the value of the live
      # option, and compare that to the value of exercising now.
  
      no_dividends = dividend_times.count
      if (no_dividends == 0) # just take the regular binomial 
          return TradingFormulas::BinomialOptions.put(s,k,r,sigma,t,steps)
      end
      steps_before_dividend = (dividend_times[0]/t*steps).to_i
     
      r_tmp = Math.exp(r*(t/steps))
      r_inv = 1.0/r_tmp
      u = Math.exp(sigma*Math.sqrt(t/steps))
      uu= u*u
      d = 1.0/u
      pUp = (r_tmp-d)/(u-d)
      pDown = 1.0 - pUp
      dividend_amount = dividend_amounts[0]
      
      tmp_dividend_times = Array.new(no_dividends-1) # temporaries with 
      tmp_dividend_amounts = Array.new(no_dividends-1) # one less dividend 
      (0..(no_dividends-2)).each do |i|
        tmp_dividend_amounts[i] = dividend_amounts[i+1].to_f
        tmp_dividend_times[i]= dividend_times[i+1].to_f - dividend_times[0].to_f
      end
      
      prices = Array.new(steps_before_dividend+1)
      put_values = Array.new(steps_before_dividend+1)
      prices[0] = s*(d**steps_before_dividend)
      
      (1..(steps_before_dividend+1)).each do |i|
        prices[i] = uu*prices[i-1]
      end
          
      (0..(steps_before_dividend+1)).each do |i|
          value_alive = TradingFormulas::BinomialOptions.discrete_dividends_put(
              prices[i]-dividend_amount, k, r, sigma, 
              t-dividend_times[0], # time after first dividend
              steps-steps_before_dividend, 
              tmp_dividend_times, tmp_dividend_amounts)  
          # what is the value of keeping the option alive?  Found recursively, 
          # with one less dividend, the stock price is current value 
          # less the dividend.
          put_values[i] = [value_alive,(k-prices[i])].max # compare to exercising now
      end
      
      (steps_before_dividend-1).downto(0) do |step|
        (0..(steps+1)).each do |i|
          prices[i] = d*prices[i+1].to_f
          put_values[i] = (pDown*put_values[i].to_f+pUp*put_values[i+1].to_f)*r_inv
          put_values[i] = [put_values[i], k-prices[i]].max# check for exercise
        end
      end       
      return put_values[0]
    end
    
    ##
    # American Option (Call) with proportional dividend payments 
    # using binomial approximations
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price,
    # +r+: interest rate
    # +sigma+: volatility 
    # +t+: time to maturity 
    # +steps+: Number of steps in binomial tree
    # +dividend_times+: Array of dividend times. (Ex: [0.25, 0.75] for 1/4 and 3/4 of a year)
    # +dividend_yields+: Array of dividend yields for the 'dividend_times'
    # *Returns* Option price
    def self.proportional_dividends_call(s, k, r, sigma, t, steps, dividend_times, dividend_yields)
      # note that the last dividend date should be before the expiry date, problems if dividend at terminal node
      no_dividends= dividend_times.count
      if (no_dividends == 0)
          return TradingFormulas::BinomialOptions.call(s,k,r,sigma,t,steps) # price w/o dividends
      end
      
      delta_t = t/steps
      r_tmp = Math.exp(r*delta_t)
      r_inv = 1.0/r_tmp
      u = Math.exp(sigma*Math.sqrt(delta_t))
      uu= u*u
      d = 1.0/u
      pUp = (r_tmp-d)/(u-d)
      pDown = 1.0 - pUp
      dividend_steps = Array.new(no_dividends) # when dividends are paid
      
      (0..(no_dividends)).each do |i|
          dividend_steps[i] = (dividend_times[i].to_f/t*steps).to_i
      end
      prices = Array.new(steps+1)
      call_prices = Array.new(steps+1)
      prices[0] = s*(d**steps)# adjust downward terminal prices by dividends
      
      (0..(no_dividends)).each do |i|
        prices[0] = prices[0].to_f * (1.0-dividend_yields[i].to_f)
      end
      
      (1..(steps+1)).each do |i|
        prices[i] = uu*prices[i-1].to_f
      end
      
      (1..(steps+1)).each do |i|
        call_prices[i] = [0.0, (prices[i]-k)].max
      end
      
      (steps-1).downto(0) do |step|
        (0..(no_dividends)).each do |i| # check whether dividend paid      
          if (step==dividend_steps[i])
            (0..(step+2)).each do |j|
              prices[j]*=(1.0/(1.0-dividend_yields[i].to_f))
            end            
          end
        end
        (0..(step+1)).each do |i|           
          call_prices[i] = (pDown*call_prices[i].to_f+pUp*call_prices[i+1].to_f)*r_inv
          prices[i] = d*prices[i+1].to_f
          call_prices[i] = [call_prices[i].to_f, prices[i].to_f-k].max #check for exercise
        end
      end
      return call_prices[0]
    end
    
    ##
    # American Option (Put) with proportional dividend payments 
    # using binomial approximations
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price,
    # +r+: interest rate
    # +sigma+: volatility 
    # +t+: time to maturity 
    # +steps+: Number of steps in binomial tree
    # +dividend_times+: Array of dividend times. (Ex: [0.25, 0.75] for 1/4 and 3/4 of a year)
    # +dividend_yields+: Array of dividend yields for the 'dividend_times'
    # *Returns* Option price
    def self.proportional_dividends_put(s, k, r, sigma, t, steps, dividend_times, dividend_yields)
      # when one assume a dividend yield, the binomial tree recombines 
      # note that the last dividend date should be before the expiry date
      no_dividends= dividend_times.count
      if (no_dividends == 0) # just take the regular binomial 
          return TradingFormulas::BinomialOptions.put(s,k,r,sigma,t,steps)
      end
      
      r_tmp = Math.exp(r*(t/steps))
      r_inv = 1.0/r_tmp
      u = Math.exp(sigma*Math.sqrt(t/steps))
      uu= u*u
      d = 1.0/u
      pUp   = (r_tmp-d)/(u-d)
      pDown = 1.0 - pUp
      dividend_steps = Array.new(no_dividends) # when dividends are paid
      
      (0..(no_dividends)).each do |i|
        dividend_steps[i] = (dividend_times[i].to_f/t*steps).to_i
      end
      prices = Array.new(steps+1)
      put_prices = Array.new(steps+1)
      prices[0] = s*(d**steps);
      
      (0..(no_dividends)).each do |i|
        prices[0] = prices[0] * (1.0-dividend_yields[i].to_f)
      end
      
      (1..(steps+1)).each do |i|
        prices[i] = uu*prices[i-1].to_f #terminal tree nodes
      end
  
      (1..(steps+1)).each do |i|
        put_prices[i] = [0.0, (k-prices[i])].max
      end
      
      (steps-1).downto(0) do |step|
        (0..(no_dividends)).each do |i| # check whether dividend paid
          if (step==dividend_steps[i])
            (0..(step+2)).each do |j|
              prices[j]*=(1.0/(1.0-dividend_yields[i].to_f))
            end
          end
        end
        (0..(step+1)).each do |i| 
          prices[i] = d*prices[i+1].to_f
          put_prices[i] = (pDown*put_prices[i].to_f+pUp*put_prices[i+1].to_f)*r_inv
          put_prices[i] = [put_prices[i].to_f, k-prices[i].to_f].max # check for exercise
        end
      end
      return put_prices[0]
    end
    
    ##
    # American Option (Call) with continuous payouts  using binomial 
    # approximations.
    # (NOTE: Originally, this method was called: 'option_price_call_american_binomial'
    # that name was already in use and didn't mention the 'payout' properties of 
    # the method, so the new name is: 'option_price_call_american_binomial_payout')
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price,
    # +r+: interest rate
    # +y+: continuous payout
    # +sigma+: volatility 
    # +t+: time to maturity 
    # +steps+: Number of steps in binomial tree
    # *Returns* Option price
    def self.continuous_payout_call(s, k, r, y, sigma, t, steps)
      r_tmp = Math.exp(r*(t/steps)) # interest rate for each step
      r_inv = 1.0/r_tmp # inverse of interest rate
      u = Math.exp(sigma*Math.sqrt(t/steps)) # up movement
      uu = u*u
      d = 1.0/u
      p_up = (Math.exp((r-y)*(t/steps))-d)/(u-d)
      p_down = 1.0-p_up
      prices = Array.new(steps+1) # price of underlying
      prices[0] = s*(d**steps)
      
      (1..(steps+1)).each do |i|
        prices[i] = uu*prices[i-1].to_f # fill in the endnodes.
      end
      
      call_values = Array.new(steps+1) # value of corresponding call 
      (1..(steps+1)).each do |i| # call payoffs at maturity
          call_values[i] = [0.0, (prices[i].to_f-k)].max
      end
      
      (steps-1).downto(0) do |step|
        (0..(step+1)).each do |i|
          call_values[i] = (p_up*call_values[i+1].to_f+p_down*call_values[i].to_f)*r_inv
          prices[i] = d*prices[i+1].to_f
          call_values[i] = [call_values[i].to_f,prices[i].to_f-k].max # check for exercise
        end
      end
      return call_values[0]
    end
    
    ##
    # American Option (Put) with continuous payouts  using binomial 
    # approximations.
    # (NOTE: Originally, this method was called: 'option_price_call_american_binomial'
    # that name was already in use and didn't mention the 'payout' properties of 
    # the method, so the new name is: 'option_price_call_american_binomial_payout')
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price,
    # +r+: interest rate
    # +y+: continuous payout
    # +sigma+: volatility 
    # +t+: time to maturity 
    # +steps+: Number of steps in binomial tree
    # *Returns* Option price
    def self.continuous_payout_put(s, k, r, y, sigma, t, steps)
      r_tmp = Math.exp(r*(t/steps)) # interest rate for each step
      r_inv = 1.0/r_tmp # inverse of interest rate
      u = Math.exp(sigma*Math.sqrt(t/steps)) # up movement
      uu = u*u
      d = 1.0/u
      p_up = (Math.exp((r-y)*(t/steps))-d)/(u-d)
      p_down = 1.0-p_up
      prices = Array.new(steps+1) # price of underlying
      put_values = Array.new(steps+1) # value of corresponding put 
      prices[0] = s*(d**steps) # fill in the endnodes.
      
      (1..(steps+1)).each do |i|
        prices[i] = uu*prices[i-1].to_f
      end
      
      (1..(steps+1)).each do |i|
          put_values[i] = [0.0, (k-prices[i].to_f)].max # put payoffs at maturity
      end
      
      (steps-1).downto(0) do |step|
        (0..(step+1)).each do |i|
          put_values[i] = (p_up*put_values[i+1].to_f+p_down*put_values[i].to_f)*r_inv
          prices[i] = d*prices[i+1].to_f
          put_values[i] = [put_values[i].to_f,(k-prices[i].to_f)].max # check for exercise
        end
      end
      return put_values[0]
    end
    
    ##
    #European Option (Call) using binomial approximations
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price,
    # +r+: interest rate
    # +sigma+: volatility 
    # +t+: time to maturity 
    # +steps+: Number of steps in binomial tree
    # *Returns* Option price
    def self.european_call(s, k, r, sigma, t, steps)
      r_tmp = Math.exp(r*(t/steps)) # interest rate for each step
      r_inv = 1.0/r_tmp # inverse of interest rate
      u = Math.exp(sigma*Math.sqrt(t/steps)) # up movement
      uu = u*u;
      d = 1.0/u;
      p_up = (r_tmp-d)/(u-d);
      p_down = 1.0-p_up;
      prices = Array.new(steps+1) # price of underlying
      prices[0] = s*(d**steps) # fill in the endnodes.
      
      (1..(steps+1)).each do |i|
        prices[i] = uu*prices[i-1].to_f
      end
  
      call_values = Array.new(steps+1) # value of corresponding call 
     
      (0..(steps+1)).each do |i|
        call_values[i] = [0.0, (prices[i]-k)].max # call payoffs at maturity
      end
      
      (steps-1).downto(0) do |step|
        (0..(step+1)).each do |i|
          call_values[i] = (p_up*call_values[i+1].to_f+p_down*call_values[i].to_f)*r_inv
        end
      end
      return call_values[0]
    end
    
    ##
    #European Option (Put) using binomial approximations
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price,
    # +r+: interest rate
    # +sigma+: volatility 
    # +t+: time to maturity 
    # +steps+: Number of steps in binomial tree
    # *Returns* Option price
    def self.european_put(s, k, r, sigma, t, steps)
      r_tmp = Math.exp(r*(t/steps)) # interest rate for each step
      r_inv = 1.0/r_tmp # inverse of interest rate
      u = Math.exp(sigma*Math.sqrt(t/steps)) # up movement
      uu = u*u
      d = 1.0/u
      p_up = (r_tmp-d)/(u-d)
      p_down = 1.0-p_up
      prices = Array.new(steps+1) # price of underlying
      prices[0] = s*(d**steps) # fill in the endnodes.
      
      (1..(steps+1)).each do |i|
        prices[i] = uu*prices[i-1].to_f
      end
      
      put_values = Array.new(steps+1) # value of corresponding put 
      (0..(steps+1)).each do |i|
          put_values[i] = [0.0, (k-prices[i])].max # put payoffs at maturity
      end
      
      (steps-1).downto(0) do |step|
        (0..(step+1)).each do |i|
          put_values[i] = (p_up*put_values[i+1].to_f+p_down*put_values[i].to_f)*r_inv
        end
      end
      return put_values[0]
    end
    
  end
end