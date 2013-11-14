class MultiCriteriaAnalysis < ActiveRecord::Base
  attr_accessible :agenda_id, :title, :description

  has_many :options, class_name: 'McaOption'
  has_many :criteria, class_name: 'McaCriteria'

  def self.create_mca_data

    agenda_id = 35
    mca_title = 'MCA test 1'
    mca_description = 'MCA test 1 description'
    options = [
        {title: 'On-Road Bicycle Lanes New - Cathedral Avenue', text:'Cathedral Ave (Maitland St- Sanford St - Chapman R/Lester St) 350m. Edge lines to reduce traffic lanes to no less than 3.2m & Bicycle Symbols every 100m'},
        {title: 'Shared Path Link on Brand Hwy South of Broadhead Avenue in front of the GULL service station.', text:'Design and construction of approximately 65 lm of concrete shared path 2.5m wide.'},
        {title: 'Eastwood Road - Abraham Street Intersection Upgrade', text:'Upgrade Eastwood Road-Abraham Street Intersection to 4 leg traffic signals. Civil Works component'},
        {title: 'Construction of New 2700 metre Runway', text:'To construct a new 2700 metre runway and associated taxiways including conversion of the current runway 03/21 to a taxiway on Airport land east of the current main runway 03/21.'},
        {title: 'Greenough Museum', text:'Remove exterior paint to all brick and stone surfaces and re-limewash all walls'},
        {title: 'Renewable and Energy Efficiency Projects (Civic Centre)', text:'Install new solar, wind or geothermal systems to City Buildings '},
        {title: 'Chapman River CARE Project Stage 1', text:'Fencing Honeysuckle Drive - Sunnybanks Sunnybanks - Tersonia Way Strath Rd - Drew St Crescent (Broome - Green), etc.'},
        {title: 'Youth Hub', text:'The Youth Hub should be a space that young people will naturally be drawn to and where they will want to “hang out”.'},
        {title: 'CCTV Eastern Breakwater', text:'Extend CCTV Network along Eastern Breakwater'},
        {title: 'Stormwater drainage South Pipe, Mahomets', text:'extend south pipe 25m and upgrade the outfall discharge'}
    ]

    panel_criteria = [
        {title: 'Community benefit compared to the financial', text: 'Community benefit compared to the financial'},
        {title: 'Protection of the natural environment balanced with community enjoyment', text: 'Protection of the natural environment balanced with community enjoyment'},
        {title: 'Flow of benefits to the local economy and employment', text: 'Flow of benefits to the local economy and employment'},
        {title: 'Allows for future population retention and growth', text: 'Allows for future population retention and growth'},
        {title: 'Whole of community value including future generations', text: 'Whole of community value including future generations'},
        {title: 'Alignment with Geraldton lifestyle (safe, firendly, city with country feel)', text: 'Alignment with Geraldton lifestyle (safe, firendly, city with country feel)'},
        {title: 'Preservation of our past while benefiting our future', text: 'Preservation of our past while benefiting our future'},
        {title: 'Attractuiveness to cultural creatives and innovators', text: 'Attractuiveness to cultural creatives and innovators'},
        {title: 'Value to special needs groups', text: 'Value to special needs groups'},
        {title: 'Impact on travel time to work and play', text: 'Impact on travel time to work and play'},
        {title: 'Enhancement of inclusivness', text: 'Enhancement of inclusivness'},
        {title: 'Community sense of ownership', text: 'Community sense of ownership'}
    ]

    mca = MultiCriteriaAnalysis.where( agenda_id: agenda_id, title: mca_title, description: mca_description  ).first_or_create


    option_ctr = 1
    options.each do |option|
      McaOption.where(multi_criteria_analysis_id: mca.id, title: option[:title]).first_or_create do |mca_option|
        mca_option.text = option[:text]
        mca_option.order_id = option_ctr
        option_ctr += 1
      end
    end

    criteria_ctr = 1
    panel_criteria.each do |criteria|
      McaCriteria.where(multi_criteria_analysis_id: mca.id, title: criteria[:title]).first_or_create do |new_criteria|
        new_criteria.category = 'panel'
        new_criteria.text = criteria[:text]
        new_criteria.order_id = criteria_ctr
        new_criteria.range = '1..5'
        new_criteria.weight = 1.0
        criteria_ctr += 1
      end
    end


    eval_ctr = 1
    mca.options[1..10
    ].each do |option|
      evaluation = McaOptionEvaluation.create user_id:373, mca_option_id: option.id, order_id: eval_ctr, category: 'group'
      eval_ctr += 1

      rating = 1
      McaCriteria.where(multi_criteria_analysis_id: mca.id).each do |criteria|
        McaRating.create mca_option_evaluation_id: evaluation.id, mca_criteria_id: criteria.id, rating:rating
        rating += 1
        rating = 1 if rating > 5
      end
    end

  end

  def self.coord_evaluation_data(params)
    mca_id = 1
    mca = MultiCriteriaAnalysis.find(mca_id)
    data = mca.attributes
    data[:options] = []
    mca.options.includes(:evaluations => [:ratings, :user]).sort{|a,b| a.order_id <=> b.order_id}.each do |option|
      option_attrs = option.attributes
      option_attrs[:evaluations] = []
      option.evaluations.each do |evaluation|
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
      data[:options].push( option_attrs )
    end
    data[:criteria] = []
    mca.criteria.sort{|a,b| a.order_id <=> b.order_id}.each do |criteria|
      data[:criteria].push( criteria.attributes )
    end
    data[:current_timestamp] = Time.new.to_i
    data
  end

  def self.group_evaluation_data(params)
    mca_id = 1
    mca = MultiCriteriaAnalysis.find(mca_id)

    option_ids = mca.options.pluck(:id)
    evaluations = McaOptionEvaluation.where(user_id: params["current_user"].id, mca_option_id: option_ids).includes(:mca_option, :ratings)

    data = mca.attributes
    data[:evaluations] = []
    evaluations.sort{|a,b| a.order_id <=> b.order_id}.each do |evaluation|
      evaluation_attrs = evaluation.attributes
      evaluation_attrs[:title] = evaluation.mca_option.title
      evaluation_attrs[:ratings] = {}
      evaluation.ratings.each do |rating|
        evaluation_attrs[:ratings][rating.mca_criteria_id] = rating.rating
      end
      data[:evaluations].push( evaluation_attrs )
    end
    data[:criteria] = []
    mca.criteria.sort{|a,b| a.order_id <=> b.order_id}.each do |criteria|
      data[:criteria].push( criteria.attributes )
    end
    data[:current_timestamp] = Time.new.to_i
    data
  end

end
