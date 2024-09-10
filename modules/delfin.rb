module Delfin
  module_function

  def call
    'https://delfin.app/'
  rescue StandardError
    'Something wrong'
  end
end
