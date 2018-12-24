require File.dirname(__FILE__) + '/../test_helper'
require 'tipo_de_cambio_controller'

# Re-raise errors caught by the controller.
class TipoDeCambioController; def rescue_action(e) raise e end; end

class TipoDeCambioControllerTest < Test::Unit::TestCase
  def setup
    @controller = TipoDeCambioController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
