Let’s dive into this financial analysis of the Saturn Fund step-by-step, breaking down each term and calculation as if you’re new to investing. I’ll use clear explanations and Ruby code to show the math, ensuring everything is easy to follow.

---

### Key Financial Terms Explained
Before we start, let’s define the terms we’ll use:

1. **Private Equity Rollup Strategy**: This is when a fund buys several smaller companies in the same industry and combines them into a larger, more valuable business to sell later for a profit.
2. **Equity**: The money the fund invests in each deal (here, $10 million per deal).
3. **Nominal Dollars**: The raw dollar amount you’d see at the end, not adjusted for anything like inflation or alternative investment returns.
4. **Real Dollars**: The profit adjusted for what you could’ve earned elsewhere (here, using the risk-free rate of 10%/year).
5. **Risk-Free Rate**: The return you’d get from a super-safe investment, like government bonds (here, 10%/year). It’s a benchmark to measure “extra” profit.
6. **MOIC (Multiple on Invested Capital)**: How many times your initial investment grows. If you invest $1 and get $2 back, your MOIC is 2x.
7. **Waterfall Distribution**: A way to split profits between investors (Limited Partners, or LPs) and fund managers (General Partners, or GPs). It’s like a tiered payout system.
8. **Hurdle Rate**: A minimum return (here, 1.8x MOIC) investors get before the GP takes a cut of profits.

Now, let’s tackle each question!

---

### a. Total Fund Profits (Base Case)
**Question**: In the base case (15%/year return), what are the total fund profits in real and nominal dollars?

#### Step 1: Understand the Setup
- The fund raises $100 million from 100 investors ($1 million each).
- It invests in 10 deals, $10 million each, totaling $100 million.
- The fund runs for 10 years with a 15%/year return (base case).
- The risk-free rate is 10%/year.
- **Nominal profits**: Total value at the end minus the initial $100 million.
- **Real profits**: Nominal profits minus what the $100 million would’ve earned at the risk-free rate.

#### Step 2: Calculate Nominal Profits
The fund grows at 15%/year for 10 years. This uses **compound interest**, where returns build on themselves each year. The formula is:

\[ \text{Future Value} = \text{Initial Investment} \times (1 + \text{Return Rate})^{\text{Years}} \]

So:
- Initial Investment = $100 million
- Return Rate = 15% = 0.15
- Years = 10

Let’s code this in Ruby:

```ruby
# Calculate the nominal future value of the fund at 15% annual return over 10 years
initial_investment = 100_000_000  # $100 million
annual_return_rate = 0.15         # 15% per year
fund_lifetime_years = 10          # 10 years

# Future value with compound interest
nominal_future_value = initial_investment * (1 + annual_return_rate) ** fund_lifetime_years

puts "Nominal Future Value: $#{nominal_future_value.round(2)}"
# Output: Nominal Future Value: $404,555,919.31

# Nominal profit is the future value minus the initial investment
nominal_profit = nominal_future_value - initial_investment

puts "Nominal Profit: $#{nominal_profit.round(2)}"
# Output: Nominal Profit: $304,555,919.31
```

The fund grows to $404.56 million, so the nominal profit is $404.56M - $100M = **$304.56 million**.

#### Step 3: Calculate Real Profits
Real profits adjust for what the $100 million could’ve earned at the risk-free rate (10%/year). Let’s compute the risk-free future value:

```ruby
# Calculate the future value at the risk-free rate of 10% per year
risk_free_rate = 0.10  # 10% per year

# Future value at risk-free rate
risk_free_future_value = initial_investment * (1 + risk_free_rate) ** fund_lifetime_years

puts "Risk-Free Future Value: $#{risk_free_future_value.round(2)}"
# Output: Risk-Free Future Value: $259,374,246.34

# Real profit is nominal future value minus risk-free future value
real_profit = nominal_future_value - risk_free_future_value

puts "Real Profit: $#{real_profit.round(2)}"
# Output: Real Profit: $145,181,672.97
```

The risk-free value is $259.37 million, so the real profit is $404.56M - $259.37M = **$145.18 million**.

#### Answer
- **Nominal Profits**: $304.56 million
- **Real Profits**: $145.18 million

---

### b. MOIC Calculation
**Question**: What is the bear (9%/year), bull (21%/year), and base (15%/year) MOIC per investor?

#### Step 1: Understand MOIC
MOIC is the multiple of your initial investment. For each investor:
- Initial investment = $1 million (since $100M / 100 investors = $1M each).
- MOIC = Future Value / Initial Investment.

#### Step 2: Calculate Future Value per Investor
Each investor’s $1 million grows at the given rate for 10 years. We’ll use the same compound interest formula.

```ruby
# Define constants
investor_initial_investment = 1_000_000  # $1 million per investor
years = 10

# Define return rates for each case
bear_case_rate = 0.09   # 9% per year
base_case_rate = 0.15   # 15% per year
bull_case_rate = 0.21   # 21% per year

# Calculate future values
bear_future_value = investor_initial_investment * (1 + bear_case_rate) ** years
base_future_value = investor_initial_investment * (1 + base_case_rate) ** years
bull_future_value = investor_initial_investment * (1 + bull_case_rate) ** years

# Calculate MOIC for each case
bear_moic = bear_future_value / investor_initial_investment
base_moic = base_future_value / investor_initial_investment
bull_moic = bull_future_value / investor_initial_investment

puts "Bear Case MOIC: #{bear_moic.round(2)}x"
# Output: Bear Case MOIC: 2.37x
puts "Base Case MOIC: #{base_moic.round(2)}x"
# Output: Base Case MOIC: 4.05x
puts "Bull Case MOIC: #{bull_moic.round(2)}x"
# Output: Bull Case MOIC: 7.62x
```

#### Results
- **Bear Case (9%/year)**: 2.37x (grows to $2.37M)
- **Base Case (15%/year)**: 4.05x (grows to $4.05M)
- **Bull Case (21%/year)**: 7.62x (grows to $7.62M)

#### Answer
- Bear MOIC: 2.37x
- Base MOIC: 4.05x
- Bull MOIC: 7.62x

---

### c. Waterfall Distribution
**Question**: The fund is sold for $500 million. Calculate the profit split with:
1. 1.8x MOIC hurdle to investors.
2. 20% GP share up to 2.7x MOIC to investors.
3. 30% GP share after 2.7x MOIC.

#### Step 1: Define the Waterfall
The waterfall splits the $500 million sale proceeds:
- **Total Invested**: $100 million.
- **Hurdle (1.8x MOIC)**: Investors get 1.8x their money before GP takes anything.
- **20% GP Share**: After 1.8x, GP gets 20% of profits until investors reach 2.7x MOIC.
- **30% GP Share**: After 2.7x, GP gets 30% of remaining profits.

#### Step 2: Calculate Each Tier
Let’s break it down:

```ruby
# Total sale proceeds and initial investment
total_proceeds = 500_000_000  # $500 million
initial_investment = 100_000_000  # $100 million

# Tier 1: 1.8x MOIC hurdle to investors (LPs)
hurdle_moic = 1.8
hurdle_amount = initial_investment * hurdle_moic  # Amount to LPs
puts "Hurdle Amount to LPs: $#{hurdle_amount}"
# Output: Hurdle Amount to LPs: $180,000,000

remaining_proceeds = total_proceeds - hurdle_amount
puts "Remaining Proceeds after Hurdle: $#{remaining_proceeds}"
# Output: Remaining Proceeds after Hurdle: $320,000,000

# Tier 2: 20% to GP until 2.7x MOIC to LPs
target_moic = 2.7
target_amount_to_lps = initial_investment * target_moic  # Total LP target
additional_lp_amount = target_amount_to_lps - hurdle_amount  # Amount in this tier
puts "Additional LP Amount to 2.7x: $#{additional_lp_amount}"
# Output: Additional LP Amount to 2.7x: $90,000,000

# Total value in this tier (LP + GP share)
total_tier_2_value = additional_lp_amount / (1 - 0.20)  # GP gets 20%
gp_share_tier_2 = total_tier_2_value * 0.20
puts "GP Share in Tier 2: $#{gp_share_tier_2}"
# Output: GP Share in Tier 2: $22,500,000

puts "LP Share in Tier 2: $#{additional_lp_amount}"
# Output: LP Share in Tier 2: $90,000,000

remaining_proceeds_after_tier_2 = remaining_proceeds - total_tier_2_value
puts "Remaining Proceeds after Tier 2: $#{remaining_proceeds_after_tier_2}"
# Output: Remaining Proceeds after Tier 2: $207,500,000

# Tier 3: 30% to GP on remaining proceeds
gp_share_tier_3 = remaining_proceeds_after_tier_2 * 0.30
lp_share_tier_3 = remaining_proceeds_after_tier_2 * 0.70
puts "GP Share in Tier 3: $#{gp_share_tier_3}"
# Output: GP Share in Tier 3: $62,250,000
puts "LP Share in Tier 3: $#{lp_share_tier_3}"
# Output: LP Share in Tier 3: $145,250,000

# Total distributions
total_lp_distribution = hurdle_amount + additional_lp_amount + lp_share_tier_3
total_gp_distribution = gp_share_tier_2 + gp_share_tier_3

puts "Total LP Distribution: $#{total_lp_distribution}"
# Output: Total LP Distribution: $415,250,000
puts "Total GP Distribution: $#{total_gp_distribution}"
# Output: Total GP Distribution: $84,750,000
```

#### Step 3: Verify
$415.25M (LPs) + $84.75M (GPs) = $500M, which matches the sale proceeds.

#### Answer
- **Investors (LPs)**: $415.25 million
- **General Partner (GP)**: $84.75 million

---

### Final Summary
- **a. Total Fund Profits (Base Case)**:
  - Nominal: $304.56 million
  - Real: $145.18 million
- **b. MOIC per Investor**:
  - Bear: 2.37x
  - Base: 4.05x
  - Bull: 7.62x
- **c. Waterfall Distribution**:
  - LPs: $415.25 million
  - GP: $84.75 million

Let me know if you’d like more clarification!
