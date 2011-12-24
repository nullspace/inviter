require 'digest/md5'

class InviteController < ApplicationController
    around_filter :catch_exceptions

    private
    def catch_exceptions
        yield
    rescue => exception
        logger.debug "Caught exception in invite_controller! #{exception}"
        redirect_to(:controller => "sorry")
    end
    
    public 
    
    def show
        @rsvp = Rsvp.find(params[:id])
        key = params[:key]
        l = @rsvp.event.location
        @address = "#{l.address}, #{l.city}, #{l.state}"

        @person = @rsvp.person
        
        if key != @rsvp.key
            logger.debug "Bad key provided in invite_controller - params: #{params}"
            redirect_to(:controller => "sorry")
            return
        end
        @rsvp.visited_at = DateTime.now
        @rsvp.save
    end

    def update
        rsvp = params[:rsvp]
        person = params[:person]
        
        @rsvp = Rsvp.find(rsvp[:id])
        if rsvp[:key] != Digest::MD5.hexdigest(@rsvp.event.seed + @rsvp.person.email)
            logger.debug "Bad key provided in invite_controller update - params: #{params}"
            redirect_to(:controller => "sorry")
            return
        end
        oldemail = @rsvp.person.email
        
        @rsvp.person.update_attributes(person)
        @rsvp.update_attributes(rsvp)
                
        if oldemail != @rsvp.person.email
            InviteMailer.deliver_changed(@rsvp, current_user)
        end
        
        respond_to do |format|
            format.html { redirect_to(:action => "show", :id => @rsvp.id, :key => @rsvp.key) }
        end
    end
end
