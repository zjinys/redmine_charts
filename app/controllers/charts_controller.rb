require 'gchart'
class ChartsController < ApplicationController
  unloadable


  def index
    @project = Project.find(params[:project_id])
    due = params[:due].to_i
    @issue_by_creator =
            Gchart.pie_3d(
                    :theme => :thirty7signals,
                    :size => '400x200',
                    :data => issue_by_creator(@project.id)[0],
                    :labels=> issue_by_creator(@project.id)[1],
                    :title => 'All bugs by reporter'
            )

    @issue_by_assigner=
            Gchart.pie_3d(
                    :theme => :thirty7signals,
                    :size => '400x200',
                    :data => issue_by_assigner(@project.id)[0],
                    :labels=> issue_by_assigner(@project.id)[1],
                    :title => 'Unresovled bugs'
            )
    @issue_create_today=
            Gchart.pie_3d(
                    :theme => :thirty7signals,
                    :size => '400x200',
                    :data => issue_create_today(due, @project.id)[0],
                    :labels=> issue_create_today(due, @project.id)[1],
                    :title => 'Today reported'
            )

  end


  private

  def issue_day_create_status(due, project_id)
    if due == 0
      due = 7
    end
    issues = Issue.find_by_sql ['select count(1) c ,CONCAT(u.firstname,u.lastname) name,DATE_FORMAT(i.created_on,"%Y-%m-%e") as create_date from issues i,users u where i.author_id = u.id and to_days(now())-to_days(i.created_on)<= ? and i.project_id = 1 and i.status_id in (1,2,4,7) group by author_id,create_date', due, project_id]
    v = {}

    issues.each do |issue|
      v.store(issue.name+"("+issue.c+")", issue.c.to_i)
    end

    v
  end

  def issue_create_today(due, project_id)
    if due == 0
      due = 1
    end
    issues = Issue.find_by_sql ['select count(1) c ,CONCAT(u.firstname,u.lastname) name from issues i,users u where i.author_id = u.id and to_days(now())-to_days(i.created_on) <= ? and i.project_id = ? and i.status_id in (1,2,4,7) group by author_id', due, project_id]
    v = []
    d = []

    issues.each do |issue|
      v << issue.c.to_i
      d << issue.name+"("+issue.c+")"
    end

    [v, d]
  end

  def issue_by_creator(project_id)
    issues = Issue.find_by_sql ['select count(1) c ,CONCAT(u.firstname,u.lastname) name from issues i,users u where i.author_id = u.id and i.project_id = ? and i.status_id in (1,2,4,7) group by author_id', project_id]
    v = []
    d = []
    issues.each do |issue|
                  #v.store(issue.name+"("+issue.c+")",issue.c.to_i)
      v << issue.c.to_i
      d << issue.name + "(" + issue.c + ")"
    end
    [v, d]
  end

  def issue_by_assigner(project_id)
    issues = Issue.find_by_sql ['select count(1) c ,CONCAT(u.firstname,u.lastname) name from issues i,users u where i.assigned_to_id = u.id  and i.project_id = ? and i.status_id in (1,2,4,7) group by assigned_to_id', project_id]
    v = []
    d = []
    issues.each do |issue|
      v << issue.c.to_i
      d << issue.name+"("+issue.c+")"
    end

    [v, d]
  end
end