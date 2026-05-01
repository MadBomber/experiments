# Yahoo Finance v8 API

See Also: https://algotrading101.com/learn/yahoo-finance-api-guide/


ai -f "how do i access yahoo finance stock data for symbol AAPL using curl on the command line"

To access Yahoo Finance stock data for the symbol AAPL using curl on the command line and format the response as Markdown, you can follow these steps:

1. Open your terminal or command prompt.

2. Use the following curl command to make a GET request to the Yahoo Finance API and retrieve the stock data for symbol AAPL:

```
curl -s "https://query1.finance.yahoo.com/v8/finance/chart/AAPL" -o stock_data.json
```

This command will save the response from the API into a file named `stock_data.json` in the current directory.

3. Next, you can use a tool like `jq` to parse the JSON response and format it as Markdown. If you don't have `jq` installed, you can install it by following the instructions for your operating system.

4. Run the following command to format the stock data as Markdown:

```
jq -r '.chart.result[0]' stock_data.json | jq -r '["Date", "Open", "High", "Low", "Close", "Volume"], (.indicators.quote[0].open, .indicators.quote[0].high, .indicators.quote[0].low, .indicators.quote[0].close, .indicators.quote[0].volume) | @csv' | awk 'BEGIN {FS=","; OFS=" | "} {print $1, $2, $3, $4, $5, $6; if (NR==1) {print " --- | --- | --- | --- | --- | ---"}}'
```

This command will format the stock data as a Markdown table with columns for Date, Open, High, Low, Close, and Volume, separated by pipe (|) symbols. The table will also have a separator row with hyphens (---) between the header and the data.

5. You will now see the formatted stock data in Markdown style printed in the terminal. You can copy and paste this output into a Markdown file or any other desired location.

Note: Make sure to replace `AAPL` with the appropriate symbol for the stock you want to retrieve data for.





11:09:16 3.2.2 master venus:misc $ ai -f "is there any documentation on how to use query1.finance.yahoo.com/v8 api for retreiving stock information?"
Yes, there is documentation available on how to use the Yahoo Finance API for retrieving stock information. Below is an example of the API endpoint and the basic format of the response:

API Endpoint: `query1.finance.yahoo.com/v8`

To retrieve stock information, you can make a GET request to the API endpoint with the necessary parameters. The API supports various query parameters such as `symbol`, `modules`, `lang`, etc. These parameters can be used to specify the stock symbol and the information required.

Here is an example of a sample URL to retrieve stock information for a specific symbol:

```
https://query1.finance.yahoo.com/v8/finance/chart/{symbol}
```

Replace `{symbol}` with the desired stock symbol. You can also include additional parameters to customize the response.

The response is returned in JSON format and contains various data points related to the stock. Some commonly included information includes the historical price data, volume, open, close, high, and low values, etc.

Please refer to the official Yahoo Finance API documentation for detailed information on the available endpoints, parameters, and response formats.

Note: It's important to note that Yahoo Finance API may have specific terms of use and rate limits. Make sure to review and comply with their usage guidelines.

Markdown formatted response:

---

## Yahoo Finance API Documentation

### API Endpoint: `query1.finance.yahoo.com/v8`

To retrieve stock information, make a GET request to the API endpoint with the required parameters. The available query parameters include `symbol`, `modules`, `lang`, etc.

Example URL to retrieve stock information for a specific symbol:

```
https://query1.finance.yahoo.com/v8/finance/chart/{symbol}
```

Replace `{symbol}` with the desired stock symbol. Customize the response by including additional parameters.

The response is in JSON format and includes various stock data points such as historical price data, volume, open, close, high, and low values, etc.

For detailed information on available endpoints, parameters, and response formats, refer to the official Yahoo Finance API documentation.

> **Note**: Please review and comply with Yahoo Finance API's terms of use and rate limits.



ai -f "what data can the version 8 (v8) API provide from yahoo finance via the query1.finance.yahoo.com endpoint.  what does the complete endpoint look like for each kind of data provided.  Use the ticker AAPL as an example."


The version 8 (v8) API from Yahoo Finance, accessed via the query1.finance.yahoo.com endpoint, can provide the following data:

- Stock Quotes: Information on a specific stock, including its ticker symbol, name, current price, opening price, previous close, high and low prices for the day, volume, average volume, market cap, and more.

- Historical Data: Historical stock data for a given time period, including the open, high, low, close, and volume for each day.

- Market Summary: Summary of the overall market, including the current state of major indices like the S&P 500, Dow Jones Industrial Average, and NASDAQ.

- Company Information: Detailed information about a company, such as its profile, sector, industry, address, phone number, website, and more.

- Dividends: Dividend data for a specific stock, including the dividend amount, ex-dividend date, and payment date.

- Financial Statements: Financial statements of a company, including balance sheets, income statements, and cash flow statements.

- Analyst Recommendations: Consensus analyst recommendations for a specific stock, including target price, rating, and the number of analysts providing recommendations.

- Options Chains: Options chain data for a specific stock, including options contracts, strike prices, expiration dates, and more.

- Cryptocurrency Data: Information on various cryptocurrencies, including their ticker symbols, current price, market cap, volume, and more.

Note: The specific data available may vary depending on the endpoint and API parameters used.





ai -f "what data can the version 8 (v8) API provide from yahoo finance via the query1.finance.yahoo.com endpoint.  what does the complete endpoint look like for each kind of data provided.  Use the ticker AAPL as an example.  Show all optional query parameters, their meaning and example usage."


The version 8 (v8) API from Yahoo Finance via the query1.finance.yahoo.com endpoint can provide the following types of data for the ticker AAPL (Apple Inc.):

1. Historical price data:
   - Endpoint: `https://query1.finance.yahoo.com/v8/finance/chart/AAPL`
   - This endpoint returns the historical price data for AAPL in JSON format.
   - By default, it provides data for the last trading year, but you can specify a different time range using optional query parameters.

2. Company profile:
   - Endpoint: `https://query1.finance.yahoo.com/v8/finance/chart/AAPL`
   - This endpoint provides detailed information about the company AAPL.
   - It returns data in JSON format, including the company name, industry, sector, description, address, website, and more.

3. Financial statements:
   - Endpoint: `https://query1.finance.yahoo.com/v8/finance/chart/AAPL`
   - This endpoint allows access to various financial statements of AAPL, such as income statements, balance sheets, and cash flow statements.
   - The data is returned in JSON format, and you can specify the type of statement and the specific period through query parameters.

4. Dividend data:
   - Endpoint: `https://query1.finance.yahoo.com/v8/finance/chart/AAPL`
   - This endpoint provides dividend data for AAPL, including dividend amounts, ex-dividend dates, and payment dates.
   - The data is returned in JSON format, and you can specify the time range and frequency of dividends through optional query parameters.

Please note that the endpoints mentioned (https://query1.finance.yahoo.com/v8/finance/chart/AAPL) are the same for each type of data provided, and the specific data is accessed by configuring the query parameters according to the desired information.





ai -f "what data can the version 8 (v8) API provide from yahoo finance via the query1.finance.yahoo.com endpoint.  what does the complete endpoint look like for each kind of data provided.  Use the ticker AAPL as an example.  Show all optional query parameters, their meaning and example usage of the endpoint using curl on the command line."

The version 8 (v8) API from Yahoo Finance provides various types of data through the query1.finance.yahoo.com endpoint. Here are the different kinds of data that can be retrieved along with their corresponding complete endpoints for the ticker AAPL:

1. Stock Quote Data:
   - Endpoint: `https://query1.finance.yahoo.com/v8/finance/chart/AAPL`
   - Optional Parameters:
      - `range`: Specifies the time range of data to retrieve. Example usage: `1d` for one day, `5d` for five days, `1mo` for one month.
      - `interval`: Specifies the interval between data points. Example usage: `1m` for one minute, `1d` for one day.
   - Example Endpoint with Optional Parameters: `https://query1.finance.yahoo.com/v8/finance/chart/AAPL?range=5d&interval=1m`

2. Company Profile Data:
   - Endpoint: `https://query1.finance.yahoo.com/v8/finance/profile/AAPL`
   - No optional query parameters available for this endpoint.

3. Historical Data (EOD):
   - Endpoint: `https://query1.finance.yahoo.com/v8/finance/download/AAPL`
   - Optional Parameters:
      - `period1`: Specifies the start date of the historical data in UNIX timestamp format. Example usage: `1459468800` for April 1, 2016.
      - `period2`: Specifies the end date of the historical data in UNIX timestamp format. Example usage: `1617235200` for March 31, 2021.
      - `interval`: Specifies the interval between data points. Example usage: `1d` for daily data, `1wk` for weekly data.
   - Example Endpoint with Optional Parameters: `https://query1.finance.yahoo.com/v8/finance/download/AAPL?period1=1459468800&period2=1617235200&interval=1d`

4. Income Statement Data:
   - Endpoint: `https://query1.finance.yahoo.com/v8/finance/download/AAPL?events=income`
   - No optional query parameters available for this endpoint.

Please note that the examples above assume API calls using HTTP GET requests.






ai -f "what data can the version 8 (v8) API provide from yahoo finance via the query1.finance.yahoo.com endpoint.  what does the complete endpoint look like for each kind of data provided.  Use the ticker AAPL as an example.  Show all optional query parameters, their meaning and example usage of the endpoint using curl on the command line."

The Yahoo Finance version 8 (v8) API provides various types of data via the query1.finance.yahoo.com endpoint. Here are the different types of data that can be obtained, along with the complete endpoint URL for each type:

1. Stock Quote Data:
- Endpoint: https://query1.finance.yahoo.com/v8/finance/chart/AAPL
- Optional Query Parameters:
  - `range`: Defines the time range for the data (e.g., 1d, 5d, 1mo, 1y, etc.)
  - `interval`: Specifies the interval between data points (e.g., 1m, 5m, 1h, etc.)
- Example Usage with Curl:
  ```
  # WORKS !!!  returns JSON
  curl 'https://query1.finance.yahoo.com/v8/finance/chart/AAPL?range=1d&interval=1m'
  ```

2. Fundamental Data:
- Endpoint: https://query1.finance.yahoo.com/v8/finance/quoteSummary/AAPL
- Optional Query Parameters: None
- Example Usage with Curl:
  ```
  # Does Not Work!
  curl 'https://query1.finance.yahoo.com/v8/finance/quoteSummary/AAPL'
  ```

3. Company News:
- Endpoint: https://query1.finance.yahoo.com/v8/finance/news/AAPL
- Optional Query Parameters:
  - `count`: Specifies the number of news articles to retrieve
- Example Usage with Curl:
  ```
  # Dpes Mpt Wprl!
  curl 'https://query1.finance.yahoo.com/v8/finance/news/AAPL?count=5'
  ```

Please note that the examples provided are basic Curl commands and may require additional headers or authentication depending on your use case.





ai -f "using yahoo finance API v8, write a curl command that will return the maximum daily stock historical data available for ticker AAPL"

Here's an example of a curl command that retrieves the maximum daily stock historical data available for ticker AAPL using Yahoo Finance API v8 and formats the response as Markdown:

```bash
curl -XGET --url 'https://query1.finance.yahoo.com/v8/finance/chart/AAPL?symbol=AAPL&period1=0&period2=9999999999&interval=1d' -H 'Content-Type: application/json' -H 'User-Agent: Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.2; Trident/6.0)' | jq -r '.chart.result[0].timestamp[] as $date | {date: $date, open: .chart.result[0].indicators.quote[0].open[$date], high: .chart.result[0].indicators.quote[0].high[$date], low: .chart.result[0].indicators.quote[0].low[$date], close: .chart.result[0].indicators.quote[0].close[$date], volume: .chart.result[0].indicators.quote[0].volume[$date]} | "[" + (.date | strftime("%Y-%m-%d")) + "](#)" + "|" + (.open | tostring) + "|" + (.high | tostring) + "|" + (.low | tostring) + "|" + (.close | tostring) + "|" + (.volume | tostring)' | echo "Date | Open | High | Low | Close | Volume
---- | ---- | ---- | ---- | ------ | ------
$(cat)" | pbcopy
```

This command uses the `curl` utility to send an HTTP GET request to the Yahoo Finance API endpoint. It specifies the ticker symbol (`AAPL`) in the URL and sets `period1` and `period2` to `0` and `9999999999` respectively to retrieve the maximum historical data available. The response is then piped through `jq`, a lightweight command-line JSON processor, to extract and format the desired data. Finally, the formatted data is sent to the clipboard using the `pbcopy` command (for macOS) or you can remove the ` | pbcopy` part to simply print the formatted response to the console. Markdown formatting is applied to the response, presenting the historical stock data in a table-like structure with the appropriate column headings.




ai -f "using yahoo finance API v8, write a curl command that will download as a CSV file the maximum daily stock historical data available for ticker AAPL"


curl -o AAPL_2.csv -L --url "https://query1.finance.yahoo.com/v8/finance/chart/AAPL?range=1d&interval=1d" -H "Accept: text/csv"


The "-o AAPL.csv" option saves the output file as AAPL.csv. The "-L" option follows any redirections. The "--url" option specifies the API endpoint for historical data for the AAPL ticker. The "-H" options set the Accept and User-Agent headers to appropriate values.




curl -o AAPL_2.csv -L --url "https://query1.finance.yahoo.com/v7/finance/download/AAPL?period1=345427200&period2=1691712000&interval=1d&events=history&includeAdjustedClose=true"


to get a unix time stamp from a Date object
  Date.today.to_time.to_i




ai -f "when I access the historical stock data for ticker AAPL using curl inside of a Ruby program I get an error back from the endpoint saying 'invalid cookie'  What should I do to the curl command for that specific endpoint which will get rid of the error message"

If you are receiving an 'invalid cookie' error message when accessing the historical stock data for ticker AAPL using curl in your Ruby program, you can try the following solution:

1. Clear your cookies: The 'invalid cookie' error message could indicate that the previous cookies are causing issues. You can add the `--cookie-jar /dev/null` option to your curl command to ignore any existing cookies. This command will discard previous cookies and start fresh.

```ruby
# Did not work
`curl --cookie-jar /dev/null <YOUR_ENDPOINT_URL>`
```

2. Add user agent: Some APIs require a user agent header to be included in the request. You can set a user agent by using the `-A` or `--user-agent` option in your curl command. Make sure to replace `<YOUR_USER_AGENT>` with an appropriate user agent for your request.

```ruby
`curl -A "<YOUR_USER_AGENT>" <YOUR_ENDPOINT_URL>`
```

By implementing either or both of these suggestions, you can potentially resolve the 'invalid cookie' error.




<pre>


#################################################################
## File: stock_data.json

{
  "chart": {
    "result": [
      {
        "meta": {
          "currency": "USD",
          "symbol": "AAPL",
          "exchangeName": "NMS",
          "instrumentType": "EQUITY",
          "firstTradeDate": 345479400,
          "regularMarketTime": 1691769640,
          "gmtoffset": -14400,
          "timezone": "EDT",
          "exchangeTimezoneName": "America/New_York",
          "regularMarketPrice": 177.76,
          "chartPreviousClose": 177.73,
          "previousClose": 177.73,
          "scale": 3,
          "priceHint": 2,
          "currentTradingPeriod": {
            "pre": {
              "timezone": "EDT",
              "start": 1691740800,
              "end": 1691760600,
              "gmtoffset": -14400
            },
            "regular": {
              "timezone": "EDT",
              "start": 1691760600,
              "end": 1691784000,
              "gmtoffset": -14400
            },
            "post": {
              "timezone": "EDT",
              "start": 1691784000,
              "end": 1691798400,
              "gmtoffset": -14400
            }
          },
          "tradingPeriods": [
            [
              {
                "timezone": "EDT",
                "start": 1691760600,
                "end": 1691784000,
                "gmtoffset": -14400
              }
            ]
          ],
          "dataGranularity": "1m",
          "range": "1d",
          "validRanges": [
            "1d",
            "5d",
            "1mo",
            "3mo",
            "6mo",
            "1y",
            "2y",
            "5y",
            "10y",
            "ytd",
            "max"
          ]
        },
        "timestamp": [
          1691760600,
          1691760660,
          1691760720,
          1691760780,
          1691760840,
          1691760900,
          1691760960,
          1691761020,
          1691761080,
          1691761140,
          1691761200,
          1691761260,
          1691761320,
          1691761380,
          1691761440,
          1691761500,
          1691761560,
          1691761620,
          1691761680,
          1691761740,
          1691761800,
          1691761860,
          1691761920,
          1691761980,
          1691762040,
          1691762100,
          1691762160,
          1691762220,
          1691762280,
          1691762340,
          1691762400,
          1691762460,
          1691762520,
          1691762580,
          1691762640,
          1691762700,
          1691762760,
          1691762820,
          1691762880,
          1691762940,
          1691763000,
          1691763060,
          1691763120,
          1691763180,
          1691763240,
          1691763300,
          1691763360,
          1691763420,
          1691763480,
          1691763540,
          1691763600,
          1691763660,
          1691763720,
          1691763780,
          1691763840,
          1691763900,
          1691763960,
          1691764020,
          1691764080,
          1691764140,
          1691764200,
          1691764260,
          1691764320,
          1691764380,
          1691764440,
          1691764500,
          1691764560,
          1691764620,
          1691764680,
          1691764740,
          1691764800,
          1691764860,
          1691764920,
          1691764980,
          1691765040,
          1691765100,
          1691765160,
          1691765220,
          1691765280,
          1691765340,
          1691765400,
          1691765460,
          1691765520,
          1691765580,
          1691765640,
          1691765700,
          1691765760,
          1691765820,
          1691765880,
          1691765940,
          1691766000,
          1691766060,
          1691766120,
          1691766180,
          1691766240,
          1691766300,
          1691766360,
          1691766420,
          1691766480,
          1691766540,
          1691766600,
          1691766660,
          1691766720,
          1691766780,
          1691766840,
          1691766900,
          1691766960,
          1691767020,
          1691767080,
          1691767140,
          1691767200,
          1691767260,
          1691767320,
          1691767380,
          1691767440,
          1691767500,
          1691767560,
          1691767620,
          1691767680,
          1691767740,
          1691767800,
          1691767860,
          1691767920,
          1691767980,
          1691768040,
          1691768100,
          1691768160,
          1691768220,
          1691768280,
          1691768340,
          1691768400,
          1691768460,
          1691768520,
          1691768580,
          1691768640,
          1691768700,
          1691768760,
          1691768820,
          1691768880,
          1691768940,
          1691769000,
          1691769060,
          1691769120,
          1691769180,
          1691769240,
          1691769300,
          1691769360,
          1691769420,
          1691769480,
          1691769540,
          1691769600,
          1691769640
        ],
        "indicators": {
          "quote": [
            {
              "high": [
                177.5,
                177.5,
                177.27999877929688,
                177.5050048828125,
                177.47999572753906,
                177.5,
                177.58999633789062,
                177.58999633789062,
                177.52000427246094,
                177.6199951171875,
                177.60000610351562,
                177.4600067138672,
                177.4199981689453,
                177.35000610351562,
                177.44000244140625,
                177.35000610351562,
                177.2100067138672,
                177.1999969482422,
                177.14999389648438,
                177.14500427246094,
                177.02000427246094,
                177.0,
                176.97000122070312,
                176.86000061035156,
                176.94000244140625,
                177.02999877929688,
                177.0699005126953,
                177.00999450683594,
                177.00999450683594,
                177.0,
                177.36000061035156,
                177.35000610351562,
                177.52999877929688,
                177.5500030517578,
                177.52999877929688,
                177.67999267578125,
                177.64500427246094,
                177.5800018310547,
                177.57000732421875,
                177.5,
                177.4499969482422,
                177.52000427246094,
                177.82000732421875,
                177.85000610351562,
                177.97000122070312,
                178.01800537109375,
                178.02999877929688,
                178.04989624023438,
                177.97000122070312,
                178.16000366210938,
                178.36000061035156,
                178.4600067138672,
                178.4199981689453,
                178.5500030517578,
                178.6199951171875,
                178.55999755859375,
                178.57000732421875,
                178.57000732421875,
                178.44500732421875,
                178.36000061035156,
                178.39999389648438,
                178.47000122070312,
                178.4149932861328,
                178.3397979736328,
                178.14999389648438,
                178.11000061035156,
                178.17999267578125,
                178.3000030517578,
                178.5,
                178.47999572753906,
                178.60499572753906,
                178.57000732421875,
                178.52000427246094,
                178.50999450683594,
                178.58999633789062,
                178.57000732421875,
                178.49729919433594,
                178.60000610351562,
                178.60000610351562,
                178.42999267578125,
                178.4199981689453,
                178.2899932861328,
                178.25909423828125,
                178.13729858398438,
                178.07000732421875,
                178.14999389648438,
                178.19000244140625,
                178.1750030517578,
                178.15499877929688,
                178.05499267578125,
                178.14500427246094,
                178.13999938964844,
                178.0800018310547,
                178.14990234375,
                178.18499755859375,
                178.14999389648438,
                178.05999755859375,
                178.02000427246094,
                177.97999572753906,
                177.92999267578125,
                177.9199981689453,
                177.8000030517578,
                177.79989624023438,
                177.82000732421875,
                177.6699981689453,
                177.66000366210938,
                177.64999389648438,
                177.67999267578125,
                177.58999633789062,
                177.63999938964844,
                177.6649932861328,
                177.6699981689453,
                177.66709899902344,
                177.6199951171875,
                177.52000427246094,
                177.5399932861328,
                177.6199951171875,
                177.60000610351562,
                177.61000061035156,
                177.52999877929688,
                177.6300048828125,
                177.6199951171875,
                177.57989501953125,
                177.57000732421875,
                177.44000244140625,
                177.4873046875,
                177.61000061035156,
                177.58999633789062,
                177.63499450683594,
                177.6300048828125,
                177.4989013671875,
                177.50999450683594,
                177.52000427246094,
                177.4600067138672,
                177.55999755859375,
                177.58999633789062,
                177.47999572753906,
                177.44000244140625,
                177.47000122070312,
                177.39329528808594,
                177.3990020751953,
                177.39999389648438,
                177.3800048828125,
                177.41000366210938,
                177.3822021484375,
                177.4199981689453,
                177.47999572753906,
                177.59320068359375,
                177.697998046875,
                177.75,
                null,
                177.76010131835938
              ],
              "volume": [
                1374420,
                283057,
                418625,
                231548,
                175497,
                174914,
                196319,
                251234,
                107656,
                163902,
                241178,
                221774,
                135153,
                130023,
                144816,
                144648,
                309674,
                174916,
                163476,
                123730,
                190614,
                112720,
                411940,
                196124,
                163887,
                190908,
                145907,
                111041,
                88423,
                187652,
                378746,
                185764,
                230231,
                154851,
                121363,
                228374,
                138984,
                126009,
                105929,
                153914,
                98303,
                241856,
                277695,
                168047,
                284120,
                224613,
                180737,
                127689,
                105295,
                354457,
                329775,
                252450,
                136525,
                260353,
                292940,
                198212,
                140401,
                141859,
                184768,
                131409,
                124323,
                167161,
                91804,
                168984,
                86669,
                175118,
                118555,
                141648,
                194276,
                112066,
                166316,
                132586,
                170379,
                94522,
                99052,
                133000,
                80104,
                111851,
                150400,
                107213,
                114430,
                102607,
                90569,
                112290,
                103642,
                138133,
                148065,
                90650,
                69193,
                111334,
                89056,
                99672,
                24854,
                131357,
                95126,
                62894,
                100278,
                100430,
                63229,
                57415,
                98421,
                114360,
                71932,
                183663,
                138084,
                86046,
                100684,
                73507,
                184760,
                106767,
                93151,
                87298,
                78308,
                106166,
                68952,
                77923,
                79878,
                54729,
                61902,
                63331,
                87608,
                58748,
                54647,
                85411,
                104518,
                85966,
                104870,
                55975,
                67647,
                76304,
                68220,
                82549,
                86118,
                58591,
                80782,
                0,
                73943,
                68565,
                99383,
                77092,
                55015,
                77292,
                44412,
                51475,
                80229,
                58063,
                74708,
                95986,
                135611,
                111144,
                null,
                0
              ],
              "close": [
                177.39199829101562,
                177.1199951171875,
                177.25010681152344,
                177.46499633789062,
                177.38999938964844,
                177.47999572753906,
                177.58990478515625,
                177.39999389648438,
                177.4604034423828,
                177.5399932861328,
                177.25,
                177.39149475097656,
                177.36000061035156,
                177.27999877929688,
                177.30999755859375,
                177.11000061035156,
                177.08990478515625,
                177.1199951171875,
                177.1154022216797,
                176.99989318847656,
                176.99000549316406,
                176.9600067138672,
                176.73989868164062,
                176.85000610351562,
                176.84500122070312,
                177.0,
                176.99070739746094,
                176.9250030517578,
                176.97000122070312,
                176.86000061035156,
                177.22000122070312,
                177.3350067138672,
                177.50100708007812,
                177.44000244140625,
                177.47500610351562,
                177.64010620117188,
                177.52000427246094,
                177.52999877929688,
                177.50999450683594,
                177.38999938964844,
                177.30999755859375,
                177.49000549316406,
                177.74000549316406,
                177.75120544433594,
                177.9600067138672,
                177.94009399414062,
                177.97999572753906,
                177.95089721679688,
                177.9499969482422,
                178.0800018310547,
                178.33999633789062,
                178.34500122070312,
                178.39999389648438,
                178.5059051513672,
                178.52999877929688,
                178.4600067138672,
                178.5399932861328,
                178.42999267578125,
                178.3101043701172,
                178.27000427246094,
                178.37010192871094,
                178.3350067138672,
                178.32000732421875,
                178.10000610351562,
                178.0814971923828,
                178.0791015625,
                178.139892578125,
                178.3000030517578,
                178.44500732421875,
                178.4199981689453,
                178.55999755859375,
                178.5050048828125,
                178.3800048828125,
                178.5,
                178.5449981689453,
                178.4199981689453,
                178.4499969482422,
                178.58999633789062,
                178.22000122070312,
                178.4199981689453,
                178.1999969482422,
                178.23500061035156,
                178.1199951171875,
                178.0399932861328,
                178.00999450683594,
                178.1300048828125,
                178.1199951171875,
                178.125,
                178.03500366210938,
                178.00999450683594,
                178.13999938964844,
                178.03500366210938,
                178.07000732421875,
                178.14990234375,
                178.11000061035156,
                178.0500030517578,
                177.88499450683594,
                177.86500549316406,
                177.9199981689453,
                177.89010620117188,
                177.789794921875,
                177.76010131835938,
                177.7794952392578,
                177.66209411621094,
                177.59849548339844,
                177.6199951171875,
                177.61000061035156,
                177.55999755859375,
                177.58999633789062,
                177.62989807128906,
                177.6396942138672,
                177.6199951171875,
                177.61000061035156,
                177.46499633789062,
                177.50469970703125,
                177.52000427246094,
                177.58999633789062,
                177.50990295410156,
                177.49000549316406,
                177.47000122070312,
                177.58279418945312,
                177.50999450683594,
                177.53500366210938,
                177.39500427246094,
                177.38999938964844,
                177.47999572753906,
                177.5749969482422,
                177.5800018310547,
                177.63499450683594,
                177.47999572753906,
                177.42990112304688,
                177.50999450683594,
                177.3699951171875,
                177.44000244140625,
                177.53500366210938,
                177.49000549316406,
                177.35000610351562,
                177.38999938964844,
                177.33999633789062,
                177.36500549316406,
                177.31500244140625,
                177.3699951171875,
                177.3300018310547,
                177.3699951171875,
                177.360107421875,
                177.41000366210938,
                177.47500610351562,
                177.57989501953125,
                177.63580322265625,
                177.72500610351562,
                null,
                177.76010131835938
              ],
              "low": [
                177.1999969482422,
                177.03500366210938,
                176.83999633789062,
                177.25999450683594,
                177.27000427246094,
                177.2100067138672,
                177.3800048828125,
                177.3699951171875,
                177.3800048828125,
                177.39999389648438,
                177.21429443359375,
                177.1199951171875,
                177.25,
                177.1300048828125,
                177.23500061035156,
                177.11000061035156,
                176.92999267578125,
                177.07000732421875,
                176.94000244140625,
                176.98399353027344,
                176.89999389648438,
                176.8800048828125,
                176.5500030517578,
                176.6999969482422,
                176.72999572753906,
                176.84500122070312,
                176.9199981689453,
                176.89999389648438,
                176.88999938964844,
                176.80999755859375,
                176.86000061035156,
                177.17999267578125,
                177.3249969482422,
                177.36669921875,
                177.4114990234375,
                177.4613037109375,
                177.42999267578125,
                177.42999267578125,
                177.47000122070312,
                177.35000610351562,
                177.2899932861328,
                177.30499267578125,
                177.47999572753906,
                177.72999572753906,
                177.75,
                177.9300994873047,
                177.89999389648438,
                177.94000244140625,
                177.8699951171875,
                177.90499877929688,
                178.08999633789062,
                178.25,
                178.25999450683594,
                178.3699951171875,
                178.46499633789062,
                178.42999267578125,
                178.4300994873047,
                178.4199981689453,
                178.2899932861328,
                178.2510986328125,
                178.22999572753906,
                178.3000030517578,
                178.30520629882812,
                178.0800018310547,
                178.07000732421875,
                177.9499969482422,
                178.0279998779297,
                178.1199951171875,
                178.2949981689453,
                178.3699951171875,
                178.3699951171875,
                178.4499969482422,
                178.31280517578125,
                178.27499389648438,
                178.44540405273438,
                178.4199981689453,
                178.3800048828125,
                178.44000244140625,
                178.1999969482422,
                178.20530700683594,
                178.1999969482422,
                178.14999389648438,
                178.08999633789062,
                178.02999877929688,
                177.972900390625,
                178.00999450683594,
                178.0449981689453,
                178.0800018310547,
                178.02999877929688,
                177.97500610351562,
                178.00999450683594,
                178.00999450683594,
                178.00999450683594,
                178.0500030517578,
                178.05999755859375,
                178.02999877929688,
                177.8800048828125,
                177.82000732421875,
                177.8699951171875,
                177.86000061035156,
                177.74000549316406,
                177.72500610351562,
                177.7200927734375,
                177.66000366210938,
                177.55999755859375,
                177.56500244140625,
                177.57000732421875,
                177.55999755859375,
                177.50999450683594,
                177.53500366210938,
                177.57000732421875,
                177.60000610351562,
                177.5850067138672,
                177.4600067138672,
                177.44000244140625,
                177.42999267578125,
                177.5,
                177.47250366210938,
                177.47999572753906,
                177.4600067138672,
                177.44500732421875,
                177.5,
                177.5,
                177.3699951171875,
                177.33970642089844,
                177.3800048828125,
                177.4199981689453,
                177.52760314941406,
                177.5500030517578,
                177.47000122070312,
                177.41000366210938,
                177.3800048828125,
                177.33999633789062,
                177.33999633789062,
                177.4199981689453,
                177.4700927734375,
                177.35000610351562,
                177.3300018310547,
                177.33999633789062,
                177.281005859375,
                177.30999755859375,
                177.3000030517578,
                177.30999755859375,
                177.31500244140625,
                177.3000030517578,
                177.35000610351562,
                177.36500549316406,
                177.4600067138672,
                177.57000732421875,
                177.61000061035156,
                null,
                177.76010131835938
              ],
              "open": [
                177.32000732421875,
                177.40499877929688,
                177.11099243164062,
                177.2899932861328,
                177.45010375976562,
                177.41000366210938,
                177.4700927734375,
                177.581298828125,
                177.3975067138672,
                177.46499633789062,
                177.55999755859375,
                177.26339721679688,
                177.37339782714844,
                177.35000610351562,
                177.27999877929688,
                177.30999755859375,
                177.11500549316406,
                177.07000732421875,
                177.14669799804688,
                177.11000061035156,
                176.99000549316406,
                176.99000549316406,
                176.9600067138672,
                176.72999572753906,
                176.85499572753906,
                176.85000610351562,
                176.9853057861328,
                176.99130249023438,
                176.91940307617188,
                176.96499633789062,
                176.86000061035156,
                177.22999572753906,
                177.35000610351562,
                177.5,
                177.42999267578125,
                177.47000122070312,
                177.64500427246094,
                177.5,
                177.52720642089844,
                177.49000549316406,
                177.39999389648438,
                177.30499267578125,
                177.49000549316406,
                177.75,
                177.75,
                177.9600067138672,
                177.94000244140625,
                177.97999572753906,
                177.9550018310547,
                177.9499969482422,
                178.08999633789062,
                178.3300018310547,
                178.35000610351562,
                178.39999389648438,
                178.5,
                178.53500366210938,
                178.46499633789062,
                178.54119873046875,
                178.42919921875,
                178.32000732421875,
                178.2899932861328,
                178.3800048828125,
                178.33999633789062,
                178.30999755859375,
                178.11000061035156,
                178.0850067138672,
                178.0800018310547,
                178.13900756835938,
                178.2949981689453,
                178.4499969482422,
                178.38999938964844,
                178.55999755859375,
                178.5,
                178.3699951171875,
                178.47999572753906,
                178.5449981689453,
                178.42010498046875,
                178.4499969482422,
                178.5850067138672,
                178.22000122070312,
                178.4199981689453,
                178.20419311523438,
                178.24000549316406,
                178.1300048828125,
                178.0449981689453,
                178.00999450683594,
                178.1300048828125,
                178.1199951171875,
                178.1300048828125,
                178.02999877929688,
                178.01499938964844,
                178.13999938964844,
                178.03500366210938,
                178.07000732421875,
                178.13499450683594,
                178.10000610351562,
                178.0592041015625,
                177.8800048828125,
                177.8699951171875,
                177.91000366210938,
                177.89999389648438,
                177.77999877929688,
                177.77000427246094,
                177.77999877929688,
                177.66000366210938,
                177.58999633789062,
                177.6300048828125,
                177.61709594726562,
                177.55999755859375,
                177.58999633789062,
                177.6199951171875,
                177.63999938964844,
                177.6300048828125,
                177.61000061035156,
                177.46499633789062,
                177.5,
                177.52999877929688,
                177.59500122070312,
                177.5050048828125,
                177.49000549316406,
                177.47000122070312,
                177.59500122070312,
                177.5,
                177.5399932861328,
                177.3907012939453,
                177.38999938964844,
                177.47500610351562,
                177.5800018310547,
                177.57000732421875,
                177.6300048828125,
                177.47000122070312,
                177.4199981689453,
                177.50999450683594,
                177.36990356445312,
                177.4499969482422,
                177.52999877929688,
                177.47000122070312,
                177.3699951171875,
                177.40170288085938,
                177.33999633789062,
                177.3697967529297,
                177.30999755859375,
                177.37579345703125,
                177.3350067138672,
                177.36000061035156,
                177.36000061035156,
                177.41000366210938,
                177.47000122070312,
                177.5800018310547,
                177.63499450683594,
                null,
                177.76010131835938
              ]
            }
          ]
        }
      }
    ],
    "error": null
  }
}

</pre>

