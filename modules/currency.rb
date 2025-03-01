module Currency
  module_function

  def call
    doc = Nokogiri::XML(
      URI.open('http://www.cbr.ru/scripts/XML_daily.asp?', { ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE })
    )
    us = doc.at_css('Valute[ID="R01235"]')
    us_charcode = us.at_css('CharCode').text
    us_value = us.at_css('Value').text
    eu = doc.at_css('Valute[ID="R01239"]')
    eu_charcode = eu.at_css('CharCode').text
    eu_value = eu.at_css('Value').text

    sol_value = get_response_from_bybit('SOLUSDT') || 'no data in'
    ton_value = get_response_from_bybit('TONUSDT') || 'no data in'
    btc_value = get_response_from_bybit('BTCUSDT') || 'no data in'
    trump_value = get_response_from_bybit('TRUMPUSDT') || 'no data in'


    [
      '*Курсы валют на сегодня:*',
      "🇺🇸 1 #{us_charcode} = #{us_value[0..4]} RUB",
      "🇪🇺 1 #{eu_charcode} = #{eu_value[0..4]} RUB",
      "💰 1 SOL = #{sol_value} USDT",
      "💰 1 TON = #{ton_value} USDT",
      "💰 1 BTC = #{btc_value} USDT",
      "💰 1 TRUMP = #{trump_value} USDT"
    ].join("\n")
  end

  def get_response_from_bybit(symbol)
    base_spot_bybit_url = 'https://api.bybit.com/v5/market/tickers?category=spot&symbol='
    response = make_request(base_spot_bybit_url + symbol)
    return if response.body.nil? || response.body['result'].empty?

    prepare_response(response)
  rescue => e
    puts "Error getting response from Bybit: #{response.body}"
    puts e
  end

  def make_request(url)
    HTTParty.get(url)
  end

  def prepare_response(response)
    JSON.parse(response.body)['result']['list'][0]['lastPrice']
  end
end
