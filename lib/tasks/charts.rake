require 'active_record'
require 'iconv'
require 'pp'
require 'gchart'

namespace :redmine do
  task :send_charts=>:environment do
    module Charts
      class ChartMailer < Mailer
        def send_charts(users,title,content)
          recipients users
          subject title + ' Bug informations'
          body content
          content_type "text/html"
        end
      end
      
      def self.gen
        @projects = Project.find(:all)
        due = 7
        @projects.each do |project|
          chart_dev = create_issue_day_resolved_status_chart(due, project.id)
          
          issueinfo = issue_day_create_status(due, project.id)
          issue_day_create_status_chart =
                  Gchart.line(:title => "Last 7 day issue by reportor",
                              :theme => :greyscale,
                              :size => '700x200',
                              :data => issueinfo[0],
                              :legend => issueinfo[1],
                              :axis_labels => issueinfo[2],
                              :axis_with_labels => 'x'
                  )


          issueinfo = issue_by_creator(project.id)
          issue_by_creator_chart =
                  Gchart.pie_3d(
                          :theme => :thirty7signals,
                          :size => '400x200',
                          :data => issueinfo[0],
                          :labels=> issueinfo[1],
                          :title => 'All bugs by reporter'
                  )
          issueinfo = issue_by_assigner(project.id)
          issue_by_assigner_chart=
                  Gchart.pie_3d(
                          :theme => :thirty7signals,
                          :size => '400x200',
                          :data => issueinfo[0],
                          :labels=> issueinfo[1],
                          :title => 'Unresolved bugs'
                  )

          issueinfo = issue_create_today(due, project.id)
          issue_create_today_chart=
                  Gchart.pie_3d(
                          :theme => :thirty7signals,
                          :size => '400x200',
                          :data => issueinfo[0],
                          :labels=> issueinfo[1],
                          :title => 'Today reported'
                  )
          content =
                  "<img src=#{issue_by_creator_chart}></img>" +
                  "<img src=#{issue_create_today_chart}></img>" +
                  "<img src=#{issue_by_assigner_chart}></img>" +
                  "<img src=#{issue_day_create_status_chart}></img>"
          chart_dev.each do |c|
            content += "<img src=#{c}><img>"
          end
          users = ''
          project.users.each do |u|
            if u.admin
              if users.length > 0
                users += ','
              end
              users += u.mail
            end
          end
          ChartMailer.deliver_send_charts(users,project.name,content)
        end
      end
      
      def self.create_issue_day_resolved_status_chart(due, project_id)
        issues = Issue.find_by_sql [
                                           "select i.assigned_to_id,count(1) as c, concat(u.firstname,u.lastname) as name from issues i,users u where i.assigned_to_id = u.id and i.status_id in (1,2,4,7) and i.project_id = ? group by i.assigned_to_id,name", project_id
                                   ]
        charts = []
        issues.each do |i|
          if i.c.to_i > 0
            issuesinfos = issue_day_resolved_status(i.assigned_to_id.to_i, due, project_id)
            charts <<
                    Gchart.line(:title => "Last 7 day issue by resolved by " + i.name,
                                :theme => :greyscale,
                                :size => '550x200',
                                :data => issuesinfos[0],
                                :axis_labels => issuesinfos[1],
                                :axis_with_labels => 'x'
                    )
          end
        end
        charts
      end

      def self.issue_day_resolved_status(user_id, due, project_id)
        if due == 0
          due = 7
        end
        axis_labels = []
        x_labels = []

        t = Time.now()
        axis_labels << t.strftime('%Y-%m-%d')
        x_labels << t.strftime('%m-%d')

        step = 24 * 60 * 60
        (1..due).each do |d|
          t1 = t - d * step
          axis_labels << t1.strftime('%Y-%m-%d')
          x_labels << t1.strftime('%m-%d')
        end


        issues = Issue.find_by_sql [
                                           "select count(1) c,CONCAT(u.firstname,u.lastname) name,DATE_FORMAT(j.created_on,'%Y-%m-%d') create_date from " +
                                                   "	 journals j, " +
                                                   "	 journal_details jd, " +
                                                   "	 issues i , " +
                                                   "	 users u " +
                                                   "where	" +
                                                   "	 i.assigned_to_id = u.id " +
                                                   "and " +
                                                   "	 i.assigned_to_id = ? " +
                                                   "and " +
                                                   "	 i.id = j.journalized_id " +
                                                   "and " +
                                                   "	 j.journalized_type = 'issue' " +
                                                   "and " +
                                                   "	 j.id = jd.journal_id " +
                                                   "and " +
                                                   "	 jd.old_value = 3 " +
                                                   "and  " +
                                                   "	 jd.value = 5 " +
                                                   "and  " +
                                                   "	 i.project_id = ? " +
                                                   "and " +
                                                   "	 to_days(now()) - to_days(j.created_on) <= ? " +
                                                   "group by name,create_date ",
                                           user_id, project_id, due
                                   ]
        data = Hash.new
        axis_labels.each do |al|
          data.store(al, 0)
        end

        issues.each do |i|
          data[i.create_date] =i.c
        end

        tmp = []
        data.sort.each do |d|
          tmp << d[1].to_i
        end

        x_labels_arr = []
        x_labels_arr << x_labels.reverse * '|'


        [tmp, x_labels_arr]
      end

      def self.issue_day_create_status(due, project_id)
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
          issues = Issue.find_by_sql ['select count(1) c ,DATE_FORMAT(i.created_on,"%Y-%m-%d") as create_date from issues i,users u where i.author_id = u.id and to_days(now())-to_days(i.created_on)<= ? and i.project_id = ? and i.status_id in (1,2,4,7) and author_id = ? group by create_date', due, project_id, a]
          data = Hash.new
          axis_labels.each do |al|
            data.store(al, 0)
          end
          issues.each do |i|
            data[i.create_date] =i.c
          end

          tmp = []
          data.sort.each do |d|
            tmp << d[1].to_i
          end
          ret_val << tmp
        end


        x_labels_arr = []
        x_labels_arr << x_labels.reverse * '|'


        [ret_val, legend, x_labels_arr]
      end

      def self.issue_create_today(due, project_id)
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

      def self.issue_by_creator(project_id)
        issues = Issue.find_by_sql ['select count(1) c ,CONCAT(u.firstname,u.lastname) name from issues i,users u where i.author_id = u.id and i.project_id = ? and i.status_id in (1,2,4,7) group by author_id', project_id]
        v = []
        d = []
        issues.each do |issue|
          v << issue.c.to_i
          d << issue.name + "(" + issue.c + ")"
        end
        [v, d]
      end

      def self.issue_by_assigner(project_id)
        issues = Issue.find_by_sql ['select count(1) c ,CONCAT(u.firstname,u.lastname) name from issues i,users u where i.assigned_to_id = u.id	 and i.project_id = ? and i.status_id in (1,2,4,7) group by assigned_to_id', project_id]
        v = []
        d = []
        issues.each do |issue|
          v << issue.c.to_i
          d << issue.name+"("+issue.c+")"
        end

        [v, d]
      end

    end

    Charts.gen
  end
end