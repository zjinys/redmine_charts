require 'redmine'

Redmine::Plugin.register :redmine_charts do
  name 'Redmine Charts plugin'
  author 'Asiacom'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://www.asiacom-online.com'
  author_url 'http://www.asiacom-online.com/about'
  
  permission :charts,{:charts=>[:index]},:public=>true
  menu :project_menu,:charts,{:controller=>'charts',:action=>'index'},:caption=>'Charts',:param => :project_id
end
