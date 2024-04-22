module TradingFormulas
  ##
  # Author:: Matt.Osentoski (matt.osentoski@gmail.com)
  #
  # This module contains formulas based on the Black Scholes model
  # Converted to Python from "Financial Numerical Recipes in C" by:
  # Bernt Arne Odegaard
  # http://finance.bi.no/~bernt/gcc_prog/index.html
  #
  class BlackScholes
    
    ##
    # Normal distribution
    #
    # +z+: Value to apply to a Normal distribution
    # *Returns* Normal distribution
    #
    def self.n(z)
      return (1.0/Math.sqrt(2.0*Math::PI))*Math.exp(-0.5*z*z)  
    end
    
    ##
    # Cumulative normal distribution
    #
    # +z+: Value to apply to a Cumulative normal distribution
    # *Returns* Cumulative normal distribution
    #
    def self.N(z)
      if (z >  6.0)  # this guards against overflow 
        return 1.0
      end 
      if (z < -6.0)
        return 0.0
      end
  
      b1 =  0.31938153 
      b2 = -0.356563782
      b3 =  1.781477937
      b4 = -1.821255978
      b5 =  1.330274429
      p  =  0.2316419
      c2 =  0.3989423
  
      a = z.abs 
      t = 1.0/(1.0+a*p) 
      b = c2*Math.exp((-z)*(z/2.0))
      n = ((((b5*t+b4)*t+b3)*t+b2)*t+b1)*t
      n = 1.0-b*n 
      if ( z < 0.0 )
        n = 1.0 - n
      end 
      return n
    end
    
    ##
    # Black Scholes formula (Call)
    # Black and Scholes (1973) and Merton (1973)
    #
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price,
    # +r+: interest rate
    # +sigma+: volatility 
    # +time+: time to maturity 
    # *Returns* Option price
    #
    def self.call(s, k, r, sigma, time)
      time_sqrt = Math.sqrt(time)
      d1 = (Math.log(s/k)+r*time)/(sigma*time_sqrt)+0.5*sigma*time_sqrt
      d2 = d1-(sigma*time_sqrt)
      return s*N(d1) - k*Math.exp(-r*time)*N(d2)  
    end  
    
    ##
    # Black Scholes formula (Put)
    # Black and Scholes (1973) and Merton (1973)
    #
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price,
    # +r+: interest rate
    # +sigma+: volatility 
    # +time+: time to maturity 
    # *Returns* Option price
    #
    def self.put(s, k, r, sigma, time)
      time_sqrt = Math.sqrt(time)
      d1 = (Math.log(s/k)+r*time)/(sigma*time_sqrt) + 0.5*sigma*time_sqrt
      d2 = d1-(sigma*time_sqrt)
      return k*Math.exp(-r*time)*N(-d2) - s*N(-d1)
    end  
    
    ##
    # Delta of the Black Scholes formula (Call)
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price,
    # +r+: interest rate
    # +sigma+: volatility 
    # +time+: time to maturity 
    # *Returns* Delta of the option
    #
    def self.delta_call(s, k, r, sigma, time)
      time_sqrt = Math.sqrt(time)
      d1 = (Math.log(s/k)+r*time)/(sigma*time_sqrt) + 0.5*sigma*time_sqrt
      delta = N(d1)
      return delta  
    end
    
    ##
    # Delta of the Black Scholes formula (Put)
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price,
    # +r+: interest rate
    # +sigma+: volatility 
    # +time+: time to maturity 
    # *Returns* Delta of the option
    #
    def self.delta_put(s, k, r, sigma, time)
      time_sqrt = Math.sqrt(time)
      d1 = (Math.log(s/k)+r*time)/(sigma*time_sqrt) + 0.5*sigma*time_sqrt
      delta = -N(-d1)
      return delta
    end
    
    ##
    # Calculates implied volatility for the Black Scholes formula using
    # binomial search algorithm
    # (NOTE: In the original code a large negative number was used as an
    # exception handling mechanism.  This has been replace with a generic
    # 'Exception' that is thrown.  The original code is in place and commented
    # if you want to use the pure version of this code)
    #
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price,
    # +r+: interest rate
    # +time+: time to maturity 
    # +option_price+: The price of the option
    # *Returns* Sigma (implied volatility)
    # *Raises* Exception if there is a problem with the binomial search
    #
    def self.implied_volatility_call_bisections(s,k,r,time,option_price)
      if (option_price<0.99*(s-k*Math.exp(-time*r)))  # check for arbitrage violations. 
        return 0.0                           # Option price is too low if this happens
      end
      
      # simple binomial search for the implied volatility.
      # relies on the value of the option increasing in volatility
      accuracy = 1.0e-5 # make this smaller for higher accuracy
      max_iterations = 100
      high_value = 1e10
      #ERROR = -1e40  // <--- original code
    
      # want to bracket sigma. first find a maximum sigma by finding a sigma
      # with a estimated price higher than the actual price.
      sigma_low=1e-5
      sigma_high=0.3
      price = call(s,k,r,sigma_high,time)
      while (price < option_price) 
        sigma_high = 2.0 * sigma_high # keep doubling.
        price = call(s,k,r,sigma_high,time)
        if (sigma_high>high_value)
          #return ERROR # panic, something wrong.  // <--- original code
          raise "panic, something wrong." # Comment this line if you uncomment the line above
        end
      end
      
      (0..max_iterations).each do |i|
        sigma = (sigma_low+sigma_high)*0.5
        price = call(s,k,r,sigma,time)
        test = (price-option_price)
        if (test.abs<accuracy)
          return sigma
        end
        if (test < 0.0)
          sigma_low = sigma
        else
          sigma_high = sigma
        end
      end
      #return ERROR      // <--- original code
      raise "An error occurred" # Comment this line if you uncomment the line above   
    end
    
    ##
    # Calculates implied volatility for the Black Scholes formula using
    # the Newton-Raphson formula
    # (NOTE: In the original code a large negative number was used as an
    # exception handling mechanism.  This has been replace with a generic
    # 'Exception' that is thrown.  The original code is in place and commented
    # if you want to use the pure version of this code)
    #
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price,
    # +r+: interest rate
    # +time+: time to maturity 
    # +option_price+: The price of the option
    # *Returns* Sigma (implied volatility)
    # *Raises* Exception if there is a problem with the newton formula
    #
    def self.implied_volatility_call_newton(s, k, r, time, option_price)
      if (option_price<0.99*(s-k*Math.exp(-time*r))) # check for arbitrage violations. Option price is too low if this happens
        return 0.0
      end
      
      max_iterations = 100
      accuracy = 1.0e-5
      t_sqrt = Math.sqrt(time)
  
      sigma = (option_price/s)/(0.398*t_sqrt) # find initial value
      
      (0..max_iterations).each do |i|
        price = call(s,k,r,sigma,time)
        diff = option_price -price
        if (diff.abs<accuracy)
          return sigma
        end
        d1 = (Math.log(s/k)+r*time)/(sigma*t_sqrt) + 0.5*sigma*t_sqrt
        vega = s * t_sqrt * n(d1)
        sigma = sigma + diff/vega
      end
      #return -99e10 # something screwy happened, should throw exception // <--- original code
      raise "An error occurred" # Comment this line if you uncomment the line above    
    end
    
    ##
    # Calculate partial derivatives for a Black Scholes Option (Call)
    # (NOTE: Originally, this method used argument pointer references as a
    # way of returning the partial derivatives in C++. I've removed these 
    # references from the method signature and chose to return a tuple instead.)
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price,
    # +r+: interest rate
    # +sigma+: volatility 
    # +time+: time to maturity
    # *Returns* Tuple of partial derivatives: (Delta, Gamma, Theta, Vega, Rho)
    # delta: partial wrt S
    # gamma: second partial wrt S
    # theta: partial wrt time
    # vega: partial wrt sigma
    # rho: partial wrt r
    #
    def self.partials_call(s, k, r, sigma, time)
      time_sqrt = Math.sqrt(time)
      d1 = (Math.log(s/k)+r*time)/(sigma*time_sqrt) + 0.5*sigma*time_sqrt
      d2 = d1-(sigma*time_sqrt)
      delta = N(d1)
      gamma = n(d1)/(s*sigma*time_sqrt)
      theta =- (s*sigma*n(d1))/(2*time_sqrt) - r*k*Math.exp( -r*time)*N(d2)
      vega = s * time_sqrt*n(d1)
      rho = k*time*Math.exp(-r*time)*N(d2)
      return delta, gamma, theta, vega, rho
    end
    
    ##
    # Calculate partial derivatives for a Black Scholes Option (Put)
    # (NOTE: Originally, this method used argument pointer references as a
    # way of returning the partial derivatives in C++. I've removed these 
    # references from the method signature and chose to return a tuple instead.)
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price,
    # +r+: interest rate
    # +sigma+: volatility 
    # +time+: time to maturity
    # *Returns* Tuple of partial derivatives: (Delta, Gamma, Theta, Vega, Rho)
    # Delta: partial wrt S
    # Gamma: second partial wrt S
    # Theta: partial wrt time
    # Vega: partial wrt sigma
    # Rho: partial wrt r
    #
    def self.partials_put(s, k, r, sigma, time)
      time_sqrt = Math.sqrt(time)
      d1 = (Math.log(s/k)+r*time)/(sigma*time_sqrt) + 0.5*sigma*time_sqrt 
      d2 = d1-(sigma*time_sqrt)
      delta = -N(-d1)
      gamma = n(d1)/(s*sigma*time_sqrt)
      theta = -(s*sigma*n(d1)) / (2*time_sqrt)+ r*k * Math.exp(-r*time) * N(-d2) 
      vega  = s * time_sqrt * n(d1)
      rho   = -k*time*Math.exp(-r*time) * N(-d2)
      return delta, gamma, theta, vega, rho    
    end
    
    ##
    # European option (Call) with a continuous payout. 
    # The continuous payout would be for fees associated with the asset.
    # For example, storage costs.
    # +s+: spot (underlying) price
    # +x+: strike (exercise) price,
    # +r+: interest rate
    # +q+: yield on underlying
    # +sigma+: volatility 
    # +time+: time to maturity
    # *Returns* Option price
    #
    def self.european_call_payout(s, x, r, q, sigma, time)
      sigma_sqr = sigma**2
      time_sqrt = Math.sqrt(time)
      d1 = (Math.log(s/x) + (r-q + 0.5*sigma_sqr)*time)/(sigma*time_sqrt)
      d2 = d1-(sigma*time_sqrt)
      call_price = s * Math.exp(-q*time)* N(d1) - x * Math.exp(-r*time) * N(d2)
      return call_price     
    end
    
    ##
    # European option (Put) with a continuous payout. 
    # The continuous payout would be for fees associated with the asset.
    # For example, storage costs.
    # +s+: spot (underlying) price
    # +x+: strike (exercise) price,
    # +r+: interest rate
    # +q+: yield on underlying
    # +sigma+: volatility 
    # +time+: time to maturity
    # *Returns* Option price
    #
    def self.european_put_payout(s, k, r, q, sigma, time) 
      sigma_sqr = sigma**2
      time_sqrt = Math.sqrt(time)
      d1 = (Math.log(s/k) + (r-q + 0.5*sigma_sqr)*time)/(sigma*time_sqrt)
      d2 = d1-(sigma*time_sqrt)
      put_price = k * Math.exp(-r*time)*N(-d2)-s*Math.exp(-q*time)*N(-d1)
      return put_price  
    end 
    
    ##
    # European option for known dividends (Call)
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price,
    # +r+: interest rate
    # +sigma+: volatility 
    # +time_to_maturity+: time to maturity 
    # +dividend_times+: Array of dividend times. (Ex: [0.25, 0.75] for 1/4 and 3/4 of a year)
    # +dividend_amounts+: Array of dividend amounts for the 'dividend_times'
    # *Returns* Option price
    #
    def self.european_call_dividends(s, k, r, sigma, time_to_maturity,
                                         dividend_times, dividend_amounts )
      adjusted_s = s
      dividend_times.each_index do |i|
        if (dividend_times[i]<=time_to_maturity)
          adjusted_s = adjusted_s - dividend_amounts[i] * Math.exp(-r*dividend_times[i])
        end
      end
      return call(adjusted_s,k,r,sigma,time_to_maturity)                                   
    end 
      
    ##
    # European option for known dividends (Put)
    # +s+: spot (underlying) price
    # +k+: strike (exercise) price,
    # +r+: interest rate
    # +sigma+: volatility 
    # +time_to_maturity+: time to maturity 
    # +dividend_times+: Array of dividend times. (Ex: [0.25, 0.75] for 1/4 and 3/4 of a year)
    # +dividend_amounts+: Array of dividend amounts for the 'dividend_times'
    # *Returns*: Option price  
    #
    def self.european_put_dividends(s, k, r, sigma, time_to_maturity,
                                        dividend_times, dividend_amounts ) 
      # reduce the current stock price by the amount of dividends. 
      adjusted_s=s
      dividend_times.each_index do |i|
        if (dividend_times[i]<=time_to_maturity)
          adjusted_s = adjusted_s - dividend_amounts[i] * Math.exp(-r*dividend_times[i])
        end
      end
      return put(adjusted_s,k,r,sigma,time_to_maturity)                                    
    end
                                                                
  end
end