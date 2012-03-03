require 'pp'

class EventsController < ApplicationController
    before_filter :login_required
    
    # GET /events
    # GET /events.xml
    def index
        @events = current_user.events
        
        respond_to do |format|
            format.html # index.html.erb
            format.xml  { render :xml => @events }
        end
    end

    # GET /events/1
    # GET /events/1.xml
    def show
        @event = current_user.events.find(params[:id])
        @newinvitees = {:list => ""}
        @rsvps = @event.rsvps
        respond_to do |format|
            format.html # show.html.erb
            format.xml  { render :xml => @event }
        end
    end

    # GET /events/new
    # GET /events/new.xml
    def new
        require 'securerandom'
        random_string = ActiveSupport::SecureRandom.hex(10)
        @event = Event.new
	@event['seed'] = random_string
        @locations = current_user.locations

        respond_to do |format|
            format.html # new.html.erb
            format.xml  { render :xml => @event }
        end
    end

    # GET /events/1/edit
    def edit
        @event = current_user.events.find(params[:id])
        @locations = current_user.locations
    end

    def nag
        @event = current_user.events.find(params[:id])
        rsvps = @event.rsvps.find(:all, :conditions => ["state = ?", "na"])
        
        rsvps.each do |rsvp|
            InviteMailer.deliver_nag(rsvp, current_user)
        end
        
        text = "<ul><li> " + rsvps.collect {|c| c.person.email}.join("<li>") + "</ul>"
        flash[:notice] = "Sent nags to: #{text}"
        
        respond_to do |format|
            format.html { redirect_to(:action => "show", :id => params[:id]) }
        end
    end
    
    # POST /events
    # POST /events.xml
    def create
        @event = current_user.events.build(params[:event])

        respond_to do |format|
            if @event.save
                flash[:notice] = 'Event was successfully created.'
                format.html { redirect_to(@event) }
                format.xml  { render :xml => @event, :status => :created, :location => @event }
            else
                format.html { render :action => "new" }
                format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
            end
        end
    end

    # PUT /events/1
    # PUT /events/1.xml
    def update
        @event = current_user.events.find(params[:id])

        respond_to do |format|
            if @event.update_attributes(params[:event])
                flash[:notice] = 'Event was successfully updated.'
                format.html { redirect_to(@event) }
                format.xml  { head :ok }
            else
                format.html { render :action => "edit" }
                format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
            end
        end
    end

    # DELETE /events/1
    # DELETE /events/1.xml
    def destroy
        @event = current_user.events.find(params[:id])
        @event.destroy

        respond_to do |format|
            format.html { redirect_to(events_url) }
            format.xml  { head :ok }
        end
    end

    def delinvitee
        event = current_user.events.find(params[:id])
        rsvp = event.rsvps.find(params[:rsvp])
        respond_to do |format|
            format.html { redirect_to(:action => "show", :id => params[:id]) }
        end
    end

    def newinvitees
        event = current_user.events.find(params[:id])
        list = params[:list].split(/\s+/)
        list.each do |email|
            person = Person.find(:first, :conditions => ["email = ?", email])
            if not person
                person = Person.new
                person.email = email
                person.save
            end
            rsvp = Rsvp.find(:first, :conditions => ["person_id = ? and event_id = ?", person.id, event.id])
            if not rsvp
                rsvp = event.rsvps.create({
                                              :person_id => person.id,
                                              :state => "na"
                                          })
                InviteMailer.deliver_invite(rsvp, current_user)
            end
        end

        respond_to do |format|
            format.html { redirect_to(:action => "show", :id => params[:id]) }
        end

    end

end
