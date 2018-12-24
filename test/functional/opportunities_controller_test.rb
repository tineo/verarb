require File.dirname(__FILE__) + '/../test_helper'
require 'opportunities_controller'

# Re-raise errors caught by the controller.
class OpportunitiesController; def rescue_action(e) raise e end; end

class OpportunitiesControllerTest < Test::Unit::TestCase
  def setup
    @controller = OpportunitiesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
