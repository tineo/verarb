require File.dirname(__FILE__) + '/../test_helper'
require 'projects_controller'

# Re-raise errors caught by the controller.
class ProjectsController; def rescue_action(e) raise e end; end

class ProjectsControllerTest < Test::Unit::TestCase
  
  fixtures :users, :acl_roles_users, :opportunities, :opportunities_contacts, :contacts, :accounts_opportunities, :accounts
  
  def setup
    @controller = ProjectsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_bounce_not_logged_in
    get :panel
    assert_redirected_to :controller => "users", :action => "login"
  end
  
  
  def test_login
    login_user :jpuppo
    assert_redirected_to :controller => "projects", :action => "panel"
  end
  
  
  def test_jpuppo_is_exec
    login_user :jpuppo
    assert session[:user][:roles].include?(CRM_ROLE_EXECUTIVE)
  end
  
  
  def test_jpuppo_is_admin
    login_user :jpuppo
    assert session[:user][:roles].include?(CRM_ROLE_ADMIN)
  end
  
  
  def test_new_ops
    login_user :jpuppo
    get :panel
    
    assert_not_nil assigns(:opportunities)
    assert_equal 1, assigns(:opportunities).size
    assert_equal opportunities(:new).name, assigns(:opportunities)[0].name
  end
  
  
  def test_create_new_project
    rmtree(PROJECTS_PATH + "1")
    rmtree(COSTS_PATH + "1")
    
    op = opportunities(:new)
    
    login_user :jpuppo
    get :new, :id => op.id
    
    assert_response :success
    
    post :new,
      :id                      => op.id,
      :project_type            => 0,
      :other                   => "",
      :urgente                 => "",
      :fecha_entrega           => "01/12/07",
      :empresa_vendedora       => "apoyo1",
      :hora_entrega            => "0900",
      :hora_am_pm              => "PM",
      :caracteristicas_entorno => "Blah",
      :publico_objetivo        => "",
      :dimensiones_espacio     => "10x10x20",
      :observaciones           => "w00t",
      :sugerencias             => "suggest",
      :nivel_seguridad         => "2",
      :materiales              => "Formica",
      :acabado                 => "Satinado",
      :como_se_vera            => ["FR", "AB"]
    
    assert_redirected_to :action => "edit_details"
    
    pid = assigns(:p).id
    
    
  end
end
