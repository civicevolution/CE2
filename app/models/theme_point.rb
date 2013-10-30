class ThemePoint < ActiveRecord::Base

  attr_accessible :group_id, :voter_id, :theme_id, :points, :code

  def self.themes_points(themes)

    theme_ids = themes.map(&:id)
    theme_points = {}
    total_points = 0.to_f
    max_points = 0


    ThemePoint.select('theme_id, sum(points)').where(theme_id: theme_ids).group(:theme_id).each do |tp|
      theme_points[tp.theme_id] = tp.sum
      total_points += tp.sum
      max_points = tp.sum unless max_points > tp.sum
    end
    max_points = max_points.to_f

    ltr = 'A'
    allocated_points = []
    final_themes = []
    themes.each do |theme|
      points = theme_points[theme.id] || 0
      allocated_points.push( {id: theme.id, letter: ltr, text: theme[:text].gsub(/\[quote.*\/quote\]/m,''),
                              points: points,
                              percentage: total_points > 0 ? (points/total_points*100).round : 0,
                              graph_percentage: max_points > 0 ? (points/max_points*100).round : 0
                             })
      ltr = ltr.succ
    end
    allocated_points = allocated_points.sort{|b,a| a[:points] <=> b[:points]}
  end

end
