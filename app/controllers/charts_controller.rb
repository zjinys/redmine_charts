require 'gchart'
class ChartsController < ApplicationController
  unloadable


  def index
    @project = Project.find(params[:project_id])
    due = params[:due].to_i
    colors = ['FF0000','00FF00','FF9994','000000','EEEEEE','CCCCCC','76A4FB']


    issueinfo = issue_day_create_status(due,@project.id)
    @issue_day_create_status =
            Gchart.line(:title => "Last 7 day issue by reportor",
                    :theme => :greyscale,
                    :size => '800x200',
                    :data => issueinfo[0],
                    :legend => issueinfo[1],
                    :axis_labels => issueinfo[2],
                    :axis_with_labels => 'x,y'
            )
    

    issueinfo = issue_by_creator(@project.id)
    @issue_by_creator =
            Gchart.pie_3d(
                    :theme => :thirty7signals,
                    :size => '400x200',
                    :data => issueinfo[0],
                    :labels=> issueinfo[1],
                    :title => 'All bugs by reporter'
            )
    issueinfo = issue_by_assigner(@project.id)
    @issue_by_assigner=
            Gchart.pie_3d(
                    :theme => :thirty7signals,
                    :size => '400x200',
                    :data => issueinfo[0],
                    :labels=> issueinfo[1],
                    :title => 'Unresovled bugs'
            )

    issueinfo = issue_create_today(due, @project.id)
    @issue_create_today=
            Gchart.pie_3d(
                    :theme => :thirty7signals,
                    :size => '400x200',
                    :data => issueinfo[0],
                    :labels=> issueinfo[1],
                    :title => 'Today reported'
            )

  end


  private

  def issue_day_create_status(due, project_id)
    if due == 0
      due = 7
    end
    axis_labels = []
    x_labels = []
    legend = []

    t = Time.now()
    axis_labels << t.strftime('%Y-%m-%d')
    x_labels << t.strftime('%m-%d')

    step = 24 * 60 * 60
    (1..due).each do |d|
      t1 = t - d * step
      axis_labels << t1.strftime('%Y-%m-%d')
      x_labels << t1.strftime('%m-%d')
    end



    axis_labels = axis_labels.reverse
    
    authors = Issue.find_by_sql ['select distinct i.author_id author_id,CONCAT(u.firstname,u.lastname) name from issues i,users u where i.author_id = u.id and to_days(now())-to_days(i.created_on)<= ? and i.project_id = ? and i.status_id in (1,2,4,7) group by author_id', due, project_id]

    
    author_ids = []
    authors.each do |a|
      legend << a.name
      author_ids << a.author_id
    end


    
    ret_val = []

    author_ids.each do |a|
      issues = Issue.find_by_sql ['select count(1) c ,DATE_FORMAT(i.created_on,"%Y-%m-%d") as create_date from issues i,users u where i.author_id = u.id and to_days(now())-to_days(i.created_on)<= ? and i.project_id = ? and i.status_id in (1,2,4,7) and author_id = ? group by create_date', due, project_id,a]
      data = Hash.new
      axis_labels.each do |al|
        data.store(al,0)
      end
      issues.each do |i|
        data[i.create_date] = i.c
      end
      tmp = []

      data.each_key { |key|
        p key 
        tmp << data[key].to_i
      }
      ret_val << tmp
    end

    

    x_labels_arr = []
    x_labels_arr << x_labels.reverse * '|'

    [ret_val,legend,x_labels_arr]
  end

  def issue_create_today(due, project_id)
    if due == 0
      due = 0
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