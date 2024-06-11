module Newrelic
  module_function

  def call
    "https://one.eu.newrelic.com/dashboards/detail/MzYwNjg0MnxWSVp8REFTSEJPQVJEfGRhOjMxNzAwNw?account=3606842&duration=10800000&tv-mode&state=5f976fcc-661d-1ef3-5089-18cfea39383c"
  rescue StandardError
    'Something wrong'
  end
end
