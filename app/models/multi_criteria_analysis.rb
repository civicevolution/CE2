class MultiCriteriaAnalysis < ActiveRecord::Base
  include ActiveModel::Dirty

  attr_accessible :agenda_id, :title, :description

  has_many :options, class_name: 'McaOption', dependent: :destroy
  has_many :criteria, class_name: 'McaCriteria', dependent: :destroy
  belongs_to :agenda

  def self.coord_evaluation_data(params)
    #if [5,51].include?(params['mca_id'].to_i)
    #  return MultiCriteriaAnalysis.coord_combined_evaluation_data(params)
    #
    #end


    mca = MultiCriteriaAnalysis.find( params['mca_id'] )
    data = mca.attributes
    data[:page_title] = params['page_title']
    data[:options] = []
    mca.options.includes(:evaluations => [:ratings, :user]).where(category: eval(params['categories']) ).sort{|a,b| a.order_id <=> b.order_id}.each do |option|
      option_attrs = option.attributes
      option_attrs[:evaluations] = []
      option.evaluations.each do |evaluation|
        if (params['mode'] != 'plenary' || evaluation.status == 'plenary') && evaluation.status != 'deleted'
          eval_attrs = evaluation.attributes
          eval_attrs[:last_name] = evaluation.user.last_name
          eval_attrs[:user_id] = evaluation.user.id
          eval_attrs[:category] = evaluation.category
          eval_attrs[:ratings] = {}
          evaluation.ratings.each do |rating|
            eval_attrs[:ratings][rating.mca_criteria_id] = rating.rating
          end
          option_attrs[:evaluations].push( eval_attrs )
        end
      end
      data[:options].push( option_attrs ) unless (params['mode'] == 'plenary' && option_attrs[:evaluations].size == 0)
    end
    data[:criteria] = []
    mca.criteria.sort{|a,b| a.order_id <=> b.order_id}.each do |criteria|
      data[:criteria].push( criteria.attributes )
    end
    data[:current_timestamp] = Time.new.to_i
    data
  end

  def self.group_evaluation_data(params)
    mca = MultiCriteriaAnalysis.find( params['mca_id'] )

    #option_ids = mca.options.where(category: ['Community Infrastructure', 'Corporate & Commercial']).pluck(:id)
    option_ids = mca.options.where(category: eval(params['categories']) ).pluck(:id)

    if params['mode'] == 'plenary'
      evaluations = McaOptionEvaluation.where(user_id: params["current_user"].id, mca_option_id: option_ids, status: 'plenary').includes(:mca_option, :ratings)
    else
      evaluations = McaOptionEvaluation.where(user_id: params["current_user"].id, mca_option_id: option_ids).includes(:mca_option, :ratings)
      evaluations.reject!{|e| e.status == 'plenary'}
    end

    data = mca.attributes
    data[:page_title] = params['page_title']
    data[:evaluations] = []
    evaluations.sort{|a,b| a.order_id <=> b.order_id}.each do |evaluation|
      if evaluation.status != 'deleted'
        evaluation_attrs = evaluation.attributes
        evaluation_attrs[:title] = evaluation.mca_option.title
        #evaluation_attrs[:project_id] = evaluation.mca_option.details['project_id']
        evaluation_attrs[:ratings] = {}
        evaluation.ratings.each do |rating|
          evaluation_attrs[:ratings][rating.mca_criteria_id] = rating.rating
        end
        data[:evaluations].push( evaluation_attrs )
      end
    end
    data[:criteria] = []
    mca.criteria.sort{|a,b| a.order_id <=> b.order_id}.each do |criteria|
      data[:criteria].push( criteria.attributes )
    end
    data[:current_timestamp] = Time.new.to_i
    data
  end

  def self.delete_mca(mca_ids)
    raise "CivicEvolution::McaCannotBeDeleted in PROD" unless Rails.env.development?
    mca_ids.each do |mca_id|
      begin
        mca = MultiCriteriaAnalysis.find(mca_id)
      rescue
        return
      end
      mca.criteria.each do |criteria|
        criteria.ratings.destroy_all
      end
      mca.criteria.destroy_all

      mca.options.each do |option|
        option.evaluations.destroy_all
      end
      mca.options.destroy_all
      mca.destroy
    end
  end





  def self.coord_combined_evaluation_data(params)
    mca = MultiCriteriaAnalysis.find( params['mca_id'] )
    agenda = mca.agenda
    mca_ids = agenda.details['mca_ids']

    source_keys = {
      2 => 'CGG',
      44 => 'CGG',
      3 => 'COM',
      45 => 'COM',
      4 => 'ADD',
      46 => 'ADD'
    }

    data = mca.attributes
    data[:page_title] = "Multi Criteria Analysis Results for Combined Projects"
    data[:options] = []

    criteria_map = {}

    data[:criteria] = []
    MultiCriteriaAnalysis.find( mca_ids[0] ).criteria.sort{|a,b| a.order_id <=> b.order_id}.each do |criteria|
      data[:criteria].push( criteria.attributes )
      criteria_map[ criteria.title ] = criteria.id
    end

    MultiCriteriaAnalysis.where(id: mca_ids ).each do |mca|
      source_key = source_keys[mca.id]
      mca.options.includes(:evaluations => [:ratings, :user]).sort{|a,b| a.order_id <=> b.order_id}.each do |option|
        option_attrs = option.attributes
        option_attrs[:evaluations] = []
        option_attrs['source_key'] = source_key
        #option_attrs['details']['project_id'] = "#{source_key}-#{option_attrs['details']['project_id']}"

        criteria_convert_map = {}
        mca.criteria.sort{|a,b| a.order_id <=> b.order_id}.each do |criteria|
          criteria_convert_map[criteria.id] = criteria_map[ criteria.title ]
        end

        option.evaluations.each do |evaluation|
          if evaluation.status != 'deleted'
            eval_attrs = evaluation.attributes
            eval_attrs[:last_name] = evaluation.user.last_name
            eval_attrs[:user_id] = evaluation.user.id
            eval_attrs[:category] = evaluation.category
            eval_attrs[:ratings] = {}
            evaluation.ratings.each do |rating|

              eval_attrs[:ratings][  criteria_convert_map[ rating.mca_criteria_id ]  ] = rating.rating
            end
            option_attrs[:evaluations].push( eval_attrs )
          end
        end
        data[:options].push( option_attrs ) unless option_attrs[:evaluations].size == 0
      end
    end

    data[:current_timestamp] = Time.new.to_i
    data
  end

  def add_criteria(title)
    criteria_stack = []
    title.split("\n").each do |criteria_title|
      next unless criteria_title.match(/\w/)
      criteria = self.criteria.create title: criteria_title
      criteria_stack.push( criteria.attributes )
    end
    criteria_stack
  end

  def add_option(title)
    options_stack = []
    title.split("\n").each do |criteria_title|
      next unless criteria_title.match(/\w/)
      pcs = criteria_title.split('#',2)
      if pcs.size == 1
        category = ''
        option_title = pcs[0]
      else
        option_title = pcs[1]
        category = pcs[0]
      end
      option = self.options.create title: option_title, category: category
      options_stack.push( option.attributes )
    end
    options_stack
  end

  def update(key, value)
    Rails.logger.debug "MCA update key: #{key}, value: #{value}"
    case key
      when 'criteria_order'
        self.update_criteria_order( value )
        {ack: 'ok', key: key, value: value}
      when 'options_order'
        self.update_options_order( value )
        {ack: 'ok', key: key, value: value}
      when 'title'
        self.update_attribute(:title, value)
        value
      else
        Rails.logger.debug "MultiCriteriaAnalysis.update doesn't know what to do with key: #{key}"
        {ack: 'FAIL-UNKNOWN', key: key, value: value}
    end
  end

  def update_criteria_order( ordered_ids )
    ordered_ids.reject!{|id| id.to_i == 0}

    if !( ordered_ids.nil? || ordered_ids.empty?)
      ctr = 0
      order_string = ordered_ids.map{|o| "(#{ctr+=1},#{o})" }.join(',')

      sql =
          %Q|UPDATE mca_criteria SET order_id = new_order_id
FROM ( SELECT * FROM (VALUES #{order_string}) vals (new_order_id,mca_criteria_id)	) t
WHERE id = t.mca_criteria_id AND multi_criteria_analysis_id = #{self.id} |
      Rails.logger.debug "update_criteria_order with sql: #{sql}"
      ActiveRecord::Base.connection.update_sql(sql)

      # return the ordered ids as a hash that allows me to look up the order_id by comment_id to resort on browser
      ids_order_id = {}
      # the order_ids start from 1, not 0
      ordered_ids.each_index{ |i| ids_order_id[ordered_ids[i]] = i+1 }
      ids_order_id
    end
  end

  def update_options_order( ordered_ids )
    ordered_ids.reject!{|id| id.to_i == 0}

    if !( ordered_ids.nil? || ordered_ids.empty?)
      ctr = 0
      order_string = ordered_ids.map{|o| "(#{ctr+=1},#{o})" }.join(',')

      sql =
          %Q|UPDATE mca_options SET order_id = new_order_id
FROM ( SELECT * FROM (VALUES #{order_string}) vals (new_order_id,mca_option_id)	) t
WHERE id = t.mca_option_id AND multi_criteria_analysis_id = #{self.id} |
      Rails.logger.debug "update_options_order with sql: #{sql}"
      ActiveRecord::Base.connection.update_sql(sql)

      # return the ordered ids as a hash that allows me to look up the order_id by comment_id to resort on browser
      ids_order_id = {}
      # the order_ids start from 1, not 0
      ordered_ids.each_index{ |i| ids_order_id[ordered_ids[i]] = i+1 }
      ids_order_id
    end
  end

  def detailed_report
    mca = self.as_json( except: [:created_at, :updated_at] )
    mca["options"] = self.options.order(:title).map{|o| {id: o.id, title: o.title, category: o.category, data: o.data} }
    mca
  end

  def service_list(user,phase)
    data = self.data
    ids = data[phase][user.last_name]
    services = self.options.where(id: ids)
    ordered_services = []
    ids.each do |id|
      service = services.detect{|s| s.id == id}
      ordered_services.push({id: service.id, title: service.title}) unless service.nil?
    end
    ordered_services
  end

  def processed_detailed_report_data
    data = self.detailed_report

    Rails.logger.debug "^^^^^^ services & levels"
    @report = []
    data['options'].each do |service|

      service_recommendations_hash = {}
      (service[:data].try{|data| data['service_recommendations'] } || []).each do |service_recommendation|
        budget_dir_id = service_recommendation['budget_dir_id']
        service_recommendations_hash[budget_dir_id] = [] unless service_recommendations_hash[budget_dir_id]
        service_recommendations_hash[budget_dir_id].push( service_recommendation )
      end

      service_suggestions_hash = {}
      (service[:data].try{|data| data['service_suggestions'] } || []).each do |service_suggestion|
        budget_dir_id = service_suggestion['budget_dir_id']
        service_suggestions_hash[budget_dir_id] = [] unless service_suggestions_hash[budget_dir_id]
        service_suggestions_hash[budget_dir_id].push( service_suggestion )
      end


      (service[:data].try{|data| data['service_level_recommendations']} || [ {} ]).each do |level|
        actions = service_recommendations_hash[level['_id']] || [  ]
        actions.each do |action|
          row = {
              service_id: service[:id],
              service_title: service[:title],
              category: service[:category],
              level: level['service_level_recommendation'],
              specific_action: { form: action['form'], increase: action['increase'], decrease: action['decrease'], reason: action['reason']},
              suggestion: {},
              group: action['group']
          }
          @report.push(row)
        end

        suggestions = service_suggestions_hash[level['_id']] || [  ]
        suggestions.each do |suggestion|
          row = {
              service_id: service[:id],
              service_title: service[:title],
              category: service[:category],
              level: level['service_level_recommendation'],
              specific_action: {},
              suggestion: { form: suggestion['form'], text: suggestion['text']},
              group: suggestion['group']
          }
          @report.push(row)
        end

        if actions.length == 0 && suggestions.length == 0
          row = {
              service_id: service[:id],
              service_title: service[:title],
              category: service[:category],
              level: level['service_level_recommendation'],
              specific_action: {},
              suggestion: {}
          }
          @report.push(row)
        end
        #Rails.logger.debug "(#{level_ctr}) #{service[:title]} direction: #{level['service_level_recommendation']} # actions: #{actions.size}, # suggestions: #{suggestions.size}"
        Rails.logger.debug "#{service[:title]}\t#{level['service_level_recommendation']}\t#{actions.size}\t#{suggestions.size}"
      end
    end

    # iterate through the report table and mark Service and direction "As above" when they repeat
    service = ''
    level = ''
    @report.each do |row|
      if service != row[:service_title]
        service = row[:service_title]
        row[:title] = service
        row[:cat] = row[:category]
        level = ''
      else
        row[:title] = 'As above'
        row[:cat] = ''
      end

      if level != row[:level]
        level = row[:level]
        row[:level_r] = level
      else
        row[:level_r] = 'As above'
      end
    end
    @report
  end

  def direction_options(current_user)
    directions_order =  [
        "Pay less for less",
        "Pay the same for the same",
        "Pay the same with different mix",
        "Pay more for more/better"
    ]
    if current_user.first_name == 'Group'
      votes = self.data['votes'].try{|votes| votes[current_user.last_name]} || {}
    else
      votes = {}
    end
      # for coord, produce an array of votes
      #votes = self.data['votes'].try{|votes| votes["1"]} || {}
    options = []
    self.options.order(:title).each do |o|
      option = {title: o.title, id: o.id}
      direction_options = [nil,nil,nil,nil]
      o.data['service_level_recommendations'].each do |direction|
        index = directions_order.index( direction["service_level_recommendation"] )
        direction_options[index] = { id: direction['_id'], title: direction["service_level_recommendation"] }
        if current_user.first_name == 'Group'
          num_votes = votes.detect{|v| v['opt_id'] == o.id && v['dir_id'] == direction['_id']}.try{|rec| rec['votes']} || nil
          direction_options[index][:pro_votes] = num_votes
        elsif current_user.first_name == 'Coordinator'
          direction_options[index][:all_votes] = [nil, nil, nil, nil, nil, nil, nil, nil]
          votes = (self.data['votes'] || {} ).each_pair do |key,val|
            cnt = val.detect{|v| v['opt_id'] == o.id && v['dir_id'] == direction['_id']}.try{|rec| rec['votes']} || nil
            if cnt
              direction_options[index][:all_votes][key.to_i - 1] = cnt
            end
          end
        end

      end
      direction_options.reject! { |o| o.nil? }
      option['direction_options'] = direction_options
      options.push(option)
    end
    {
      report_thresholds: self.data['report_thresholds'],
      options: options
    }
  end

  def direction_votes(current_user, vote_data)
    Rails.logger.debug "Save this votes json to the mca data"
    data_will_change!
    data = self.data || {}
    data['votes'] ||= {}
    data['votes'][current_user.last_name.to_s] = vote_data
    ActiveRecord::Base.transaction do
      self.update_attribute(:data, {} )
      self.update_attribute(:data, data)
    end
    self.realtime_notification(current_user.last_name.to_s, vote_data)

  end

  def realtime_notification(group_id, data)
    data = {
        mca_id: self.id,
        group_id: group_id,
        data: data,
        updated_at: self.updated_at
    }
    message = { class: 'full_services_vote', action: "update", data: data, updated_at: Time.now.getutc, source: "RoR-RT-Notification" }
    channel = "/mca/#{self.id}/votes"
    Modules::FayeRedis::publish(message,channel)
  end
  handle_asynchronously :realtime_notification

end
