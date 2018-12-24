require File.dirname(__FILE__) + '/../test_helper'
require 'facturation_controller'

# Re-raise errors caught by the controller.
class FacturationController; def rescue_action(e) raise e end; end

class FacturationControllerTest < Test::Unit::TestCase
  def setup
    @controller = FacturationController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
