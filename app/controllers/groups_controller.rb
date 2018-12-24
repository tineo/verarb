class GroupsController < ApplicationController
  before_filter :set_tab_admin
  before_filter :check_access
  
  def list
    @groups = Group.find :all, :order => "name"
  end
  
  
  def new
    @form = Fionna.new "groups_admin"
    
    if request.post?
      @form.load_values params
      
      if @form.valid?
        g = Group.new
        g.update_attributes(@form.get_values)
        g.save
        
        redirect_to :controller => "groups", :action => "show", :id => g.id
      end
    end
  end
  
  
  def edit
    @group = Group.find params[:id]
    
    @form = Fionna.new "groups_admin"
    
    if request.post?
      @form.load_values params
      
      if @form.valid?
        @group.update_attributes(@form.get_values)
        @group.update
        
        redirect_to :action => "show", :id => @group.id
      end
    else
      @form.name = @group.name
      @form.goal = "%0.2f" % @group.goal
    end
  end
  
  
  def delete
    g = Group.find params[:id]
    GroupMember.destroy_all "group_id='#{g.id}'"
    g.destroy
    
    redirect_to :action => "list"
  end
  
  
  def show
    @group   = Group.find params[:id]
    
    # We fetch a list of possible Executives to add to this group
    execs   = User.list_of :executives
    members = GroupMember.find :all
    
    list = []
    
    members.each do |m|
      list << m.user_id
    end
    
    @execs = execs.select { |e| !(list.include? e.id) }
    
    if request.post?
      if params[:user]
        u = User.find params[:user]
        
        m = GroupMember.find_by_user_id u.id
        
        # We can't add a user who belongs to other group
        unless m
          g = GroupMember.new
          g.user_id  = u.id
          g.group_id = @group.id
          g.save
        end
        
        redirect_to :action => "show", :id => @group.id
      end
    end
  end
  
  
  def delete_member
    @group = Group.find params[:id]
    @member = GroupMember.find params[:mid]
    
    @member.destroy
    
    redirect_to :action => "show", :id => @group.id
  end
end
