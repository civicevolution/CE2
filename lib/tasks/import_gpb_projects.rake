namespace :import_gpb_projects do
  desc "Injects project_with_rating_and_group.csv into the database."
  task :import => [:environment] do
    puts "import_gpb_projects:import v5"
    require 'csv'


    agenda = Agenda.last
    # create a hash of group to user_id
    agenda_groups = {}
    agenda.participants.select{|p| p.email.match(/group/)}.each do |participant|
      agenda_groups[participant.last_name.to_i] = participant.id
    end

    agenda_groups.each_pair do |k,v|
      puts "agenda_groups[#{k}]: #{v}"
    end
    puts agenda.inspect

    mca_title = "Rate the Executive Group's top 70 capital works projects"

    puts mca_title
    mca_description = "Rate the Executive Group's top 70 capital works projects"
    puts mca_description
    mca = MultiCriteriaAnalysis.where( agenda_id: agenda.id, title: mca_title, description: mca_description  ).first_or_create

    puts mca.inspect

    option_ctr = 1
    CSV.foreach( "#{Rails.root}/projects_with_rating_and_group.csv",
                  :headers           => true,
                  :header_converters => :symbol ) do |line|

      # create the projects
      hash = line.to_hash
      option = McaOption.where(multi_criteria_analysis_id: mca.id, title: hash[:title] ).first_or_create do |mca_option|
        mca_option.text = hash[:title]
        mca_option.order_id = option_ctr
        option_ctr += 1
      end
      option.update_attribute(:details, {city_rating: hash[:exec_rating], project_id: hash[:project_id]})
      option.update_attribute(:title, hash[:title] )
      puts "option: #{option.inspect}"

      # create the evaluations
      evaluation = McaOptionEvaluation.where(user_id: agenda_groups[ hash[:group_num].to_i ], mca_option_id: option.id, category: 'group').first_or_create
      puts evaluation.inspect

      #puts "title: #{line.to_hash[:title]}"

    end

    # add 10 default criteria A..J

    criteria_ctr = 1
    letter = 'A'
    (1..10).each do |criteria|
      McaCriteria.where(multi_criteria_analysis_id: mca.id, title: letter).first_or_create do |new_criteria|
        new_criteria.category = 'panel'
        new_criteria.text = letter
        new_criteria.order_id = criteria_ctr
        new_criteria.range = '1..5'
        new_criteria.weight = 1.0
        criteria_ctr += 1
        letter = letter.succ
      end
    end




  end
end