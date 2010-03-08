class AdminController < ApplicationController
  before_filter :authorized?

  def authorized?
    logged_in? && current_user.admin
  end

  def edit_user
  end

  def update_user
    @user.update_attributes(params[:user])
    @user.save!
    redirect_to :action => 'edit_user', :user_id => @user.id
  end

  def delete_user
    @user.destroy
    redirect_to :controller => 'dashboard'
  end

  # display sessions for a user 
  def session_list
    limit = params[:limit] || 50
    @offset = params[:offset] || 0
    if(params[:ip_address])
      @user_name = 'IP '+params[:ip_address]
      @sessions = Interaction.sessions_for_ip(params[:ip_address], limit, @offset)      
    else      
      if(@user)
        @user_name = @user.login
        @sessions = Interaction.sessions_for_user(@user.id, limit, @offset)      
      else
        @user_name = 'Anonymous'
        @sessions = Interaction.sessions_for_anonymous(limit, @offset)      
      end
    end
  end
  
  def delete_spiders
    Interaction.delete_spiders
    redirect_to :action => 'session_list'
  end
  
  # display last interactions, including who did what to which
  # actor, action, object, detail 
  def interaction_list
    # interactions for a session
    if(params[:session_id])
      conditions = "session_id = '#{params['session_id']}'"
    else if(@user)
        # interactions for user
        conditions = "user_id = #{@user.id}"
      else 
        # all interactions
        conditions = nil
      end
    end
    @interactions = 
      Interaction.find(:all, {:conditions => conditions , :order => 'id ASC'})
  end
  
  # display last interactions, including who did what to which
  # actor, action, object, detail 
  def error_list
    # interactions with errors
    limit = params[:limit] || 50
    @interactions = 
      Interaction.find(:all, 
                       {:conditions => "status='incomplete'", 
                        :order => 'id DESC',
                        :limit => limit})
  end
  
  def tail_logfile
    @lines = params[:lines].to_i
    development_logfile = "#{RAILS_ROOT}/log/development.log"
    production_logfile = "#{RAILS_ROOT}/log/production.log"
    @dev_tail = `tail -#{@lines} #{development_logfile}`
    @prod_tail = `tail -#{@lines} #{production_logfile}`
  end
  

end
