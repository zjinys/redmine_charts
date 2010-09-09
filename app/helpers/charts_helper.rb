module ChartsHelper
  def charts_tabs
    tabs = [
            {:name => 'all',  :partial => 'charts', :label => :label_index},
            {:name => 'dev',  :partial => 'dev', :label => :label_dev},
            {:name => 'test', :partial => 'test', :label => :label_test}
          ]
  end
end
