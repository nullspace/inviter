module EventsHelper
    def admin_check
        unless current_user.login == SITE_CONFIG['admin_login']
            flash[:notice] = "Unauthorized access to admin area"
            redirect_to :controller => 'sorry'
        end
    end

end
