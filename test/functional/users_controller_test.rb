require File.dirname(__FILE__) + '/../test_helper'
require 'users_controller'

# Re-raise errors caught by the controller.
class UsersController; def rescue_action(e) raise e end; end

class UsersControllerTest < Test::Unit::TestCase
  
  fixtures :users, :acl_roles_users
  
  def setup
    @controller = UsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_index_page
    get :login
    assert_response :success
  end
  
  def test_login_invalid_user
    post :login, :username => "jpuppo", :password => "invalidpass"
    assert_response :success
    assert_tag :tag => "div", :child => /inv&aacute;lida/
  end
  
  def test_login_valid_user
    post :login, :username => "jpuppo", :password => "apoyocrm"
    assert_redirected_to :controller => "projects", :action => "panel"
    assert_equal "jpuppo", session[:user][:user_name]
  end
end
