class DashboardController < ApplicationController
  before_filter :set_tab_dashboard
  
  def index
    @user = User.find(session[:user][:id])
  end
end
