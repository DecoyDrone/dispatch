class ReportsController < ApplicationController

  before_filter :load_scope
  before_filter :logged_in_required, :except => [:index, :show]

  def index
    @reports = @scope.active.recent
    @perpetrator = Perpetrator.find params[:perpetrator_id] if params[:perpetrator_id].present?
    if session[:user_id].present?
      @user = current_user
      @reddit_url = ::RedditService.case_submit_link(@perpetrator, @user) if params[:perpetrator_id].present?
    else
      @reddit_url = ::RedditService.case_submit_link(@perpetrator) if params[:perpetrator_id].present?
    end
  end

  def user
    index
    render action: 'index'
  end

  def show
    @report = Report.find(params["id"])
    @perpetrator = Perpetrator.find(@report.perpetrator_id)
    if session[:user_id].present?
      @user = current_user
      @reddit_url = ::RedditService.report_submit_link(@report, @perpetrator, @user)
    else
      @reddit_url = ::RedditService.report_submit_link(@report, @perpetrator)
    end
  end

  def new
    @report = @scope.new
    3.times { @report.evidence_links.build }
  end

  def create
    @report = @scope.new(params[:report].merge(user_id: session[:user_id]))
    if @report.save
      flash[:notice] = %Q[Report Filed! To see all Reports <a href="/perpetrators/#{@report.perpetrator_id}/reports">Click Here</a>].html_safe
      redirect_to "/reports/#{@report.id}"
    else
      flash.now[:error] = @report.errors.full_messages.join(", ")
      render action: "new"
    end
  end

  def edit
    @report = Report.for_author(current_user.id).find params[:id]
    3.times { @report.evidence_links.build }
  end

  def update
    @report = Report.for_author(current_user.id).find params[:id]
      if @report.update_attributes params[:report]
        redirect_to "/user/reports"
      else
        flash.now[:error] = @report.errors.full_messages.join(", ")
        render :action => :edit
    end
  end

  def select_claim
    @report = Report.for_author(current_user.id).find params[:id]
    @perp = Perpetrator.find_by_id(@report.perpetrator_id)
    @claims = Claim.where(perpetrator_id: @perp.id).order('claims DESC')
  end

  def destroy
    @report = Report.for_author(current_user.id).find params[:id]
    redirect_to select_claim_report_path(@report) and return false if Claim.where(perpetrator_id: @report.perpetrator_id).any? && ! params[:claim_id].present?
    @report.close and redirect_to "user/reports" and return false if params[:reject] == "true"
    if params[:claim_id].present?
      @claim = Claim.find(params[:claim_id])
      reward = Reward.new(claim: @claim, report: @report)
      if reward.save
        flash[:notice] = "Report has been closed and point rewarded"
        @report.close
        redirect_to "/"
      else
        flash[:error] = "You can't reward that hunter at this time"
        redirect_to select_claim_report_path(@report)
      end
    else
      @report.close
      redirect_to "/user/reports"
    end
  end

  def logged_in_required
    return true if logged_in?
    session[:return_to] = request.fullpath
    redirect_to '/sessions/new'
  end

  def load_scope
    @scope = Report
    @scope = @scope.for_perp(params[:perpetrator_id]) if params[:perpetrator_id].present?
    @scope = @scope.for_author(current_user.id) if session[:user_id].present? and request.path == "/user/reports"
  end
end
