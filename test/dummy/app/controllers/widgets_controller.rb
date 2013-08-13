class WidgetsController < ApplicationController

  def paper_trail_enabled_for_controller
    request.user_agent != 'Disable User-Agent'
  end

  def create
    if PaperTrail.active_record_protected_attributes?
      @widget = Widget.create params[:widget]
    else
      @widget = Widget.create params[:widget].permit!
    end
    head :ok
  end

  def update
    @widget = Widget.find params[:id]
    if PaperTrail.active_record_protected_attributes?
      @widget.update_attributes params[:widget]
    else
      @widget.update_attributes params[:widget].permit!
    end
    head :ok
  end

  def destroy
    @widget = Widget.find params[:id]
    @widget.destroy
    head :ok
  end
end
