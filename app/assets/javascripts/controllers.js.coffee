# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

bootstrap_CE2 = ->
	#console.log "In bootstrap_CE2"

  if typeof Firebase == 'undefined'
    setTimeout bootstrap_CE2, 50
  else
    try
      angular.bootstrap(document,["CE2"])
    catch error
      setTimeout bootstrap_CE2, 50

bootstrap_CE2()


ce2_app = angular.module("CE2", ["ngResource","CE2.services", 'CE2.directives', 'CE2.filters',
  'ui.compat', 'ui.bootstrap', 'ngUpload'] )

ce2_app.config ($httpProvider) ->
	$httpProvider.defaults.headers.common["X-CSRF-TOKEN"] = 
		document.querySelectorAll('meta[name="csrf-token"]')[0].getAttribute('content')

ce2_app.value('Firebase', Firebase);

ce2_app.config ( [ '$stateProvider', '$routeProvider', '$urlRouterProvider',
  ($stateProvider,   $routeProvider,   $urlRouterProvider) ->
    $urlRouterProvider
      .when('/c?id', '/contacts/:id')
      .otherwise('/');
  
    $routeProvider
      .when('/user/:id', {
        redirectTo: '/contacts/:id',
      })
      .when('/haha', {
        template: '<p class="lead">Welcome to the ngStates sample</p><p>Use the menu above to navigate</p>' +
          '<p>Look at <a href="#/c?id=1">Alice</a> or <a href="#/user/42">Bob</a> to see a URL with a redirect in action.</p>',
      })
      
    $stateProvider

      .state('home', {
        url: '/home',
        templateUrl: '/assets/angular-views/home.html'
      })


      .state('about', {
        url: '/about',
        templateProvider:
          [        '$timeout', ($timeout) ->
            $timeout -> 
              "Hello <i>world</i>" 
            , 100
          ]
      })
      .state('state_temp_prov', {
        url: '/state_temp_prov',
        templateProvider:
          [        '$timeout', ($timeout) ->
            $timeout -> 
              "I am now in state1" 
            , 100
          ]
      })

      .state('issue', {
        url: '/',
        templateUrl: '/assets/angular-views/issue.html'
      })

      .state('edit-profile', {
        url: '/edit-profile'
        templateUrl: '/assets/angular-views/edit-profile.html'
      })

      .state('state1', {
        url: '/state1',
        templateUrl: '/assets/angular-views/test/state1.html'
        data:
          custom_id: 10
          custom_desc: 'circle'
        controller: ($state) ->
          console.log "$state.current.data.custom_desc: #{$state.current.data.custom_desc}"
      })
      
      .state('state2', {
        url: '/state2',
        templateUrl: '/assets/angular-views/test/state2.html'
      })
      .state('state3', {
        url: '/state3',
        templateUrl: '/assets/angular-views/test/state3.html'
        controller:  [ "$scope", "$state", "$timeout", ($scope, $state, $timeout) ->
          $scope.user = 'Brian Sullivan'
          $scope.goto_state1 = ->
            console.log "hey, I want to go to state1"
            $state.transitionTo('state1')
            $timeout ->
              $state.transitionTo('state2')
            , 2000
        ]
      })
      .state('state4', {
        url: '/state4/{userID}',
        views: 
          "":
            templateUrl: '/assets/angular-views/test/state4.html'
            resolve: { resolved_data: -> 
              title: 'My Contacts' 
              duration: '1 hour'
              weight: '5 pounds'
              height: '22 inches'
            }
            controller: [ "$scope", "$state", "$timeout", "resolved_data", "$stateParams", "$routeParams", "$location", 
              ($scope, $state, $timeout, resolved_data, $stateParams, $routeParams, $location) ->
                $scope.user = 'Brian Sullivan'
                $scope.data = resolved_data
                $scope.goto_state1 = ->
                  console.log "hey, I want to go to state4"
                  $state.transitionTo('state1')
                  $timeout ->
                    $state.transitionTo('state2')
                  , 2000
            ]
          
          "footer":
            template: "The footer"
      })

      .state('test-autogrow', {
        url: '/test-autogrow'
        templateUrl: '/assets/angular-views/test/autogrow.html'
        controller: [ "$scope", ($scope) ->
          console.log "controller for test-autogrow"
          $scope.autoGrow = (oField) ->
            if oField.scrollHeight > oField.clientHeight
              oField.style.height = oField.scrollHeight + "px"
        ]
      })

      .state('test-animation', {
        url: '/test-animation'
        templateUrl: '/assets/angular-views/test/animation.html'
        controller: [ "$scope", ($scope) ->
          console.log "controller for test-animation"
          $scope.adjust = ->
            console.log "test-animation:adjust"
            $scope.step = not $scope.step
        ]
      })

      .state('test-sortable', {
        url: '/test-sortable'
        templateUrl: "/assets/angular-views/test/sortable.html?t=#{new Date().getTime()}"
        controller: [ "$scope", ($scope) ->
          #console.log "controller for test-sortable"
          $scope.items = [
            {id: 1, order_id: 1, text: 'item 1'},
            {id: 2, order_id: 2, text: 'item 2'},
            {id: 3, order_id: 3, text: 'item 3'},
            {id: 4, order_id: 4, text: 'item 4'},
            {id: 5, order_id: 5, text: 'item 5'}
          ]
          $scope.test = ->
            console.log "test in sortable"
        ]
      })

])

ce2_app.run( ['$rootScope', '$state', '$stateParams', "Issue", "$timeout", "TemplateEngine", "$http", "$templateCache"
  ($rootScope,   $state,   $stateParams, Issue, $timeout, TemplateEngine, $http, $templateCache) ->
    $rootScope.$state = $state
    $rootScope.$stateParams = $stateParams
    $rootScope.CSRF = document.querySelectorAll('meta[name="csrf-token"]')[0].getAttribute('content')
    $rootScope.issue = Issue.data

    $rootScope.autoGrow = (oField) ->
      if oField.scrollHeight > oField.clientHeight
        oField.style.height = oField.scrollHeight + "px"

    $rootScope.simple_format = (s) ->
      ("<p>#{str}</p>" for str in unescape(s).split(/\n\n/)).join('').replace(/\n/g,'<br/>')

    $rootScope.text_select_by_mouse = ->
      #console.log "text_select_by_mouse"
      try
        [text, id, type, name, photo, coords] = capture_selection()

        $rootScope.selection =
          text: text
          id: id
          type: type
          name:name
          photo: photo

        if text
          #console.log "use this string in form:\n#{str}"
          #console.log "found select_reference: #{select_reference}"
          $rootScope.show_add_quote_to_reply_style =
            display: 'block'
            position: 'absolute'
            top: "#{coords.top}px"
            left: "#{coords.left}px"

          $timeout ->
            angular.element(document).bind('mouseup', clear_capture_selection_button)
          ,100

        else
          $rootScope.show_add_quote_to_reply_style =
            display: "none"

        $rootScope.$$phase || $rootScope.$apply()

      catch error
        console.log "conversation_select had an error: #{error}"

    $rootScope.add_quote_to_reply = ->
      sel = $rootScope.selection
      quote_insert = "[quote=#{sel.name}~#{sel.type}~#{sel.id}~#{sel.photo}]#{sel.text}[/quote]"
      #console.log "Add this quote to textarea: #{quote_insert}"

      textarea = document.getElementById('comment-preview-form').getElementsByTagName('textarea')[0]
      textarea.value += "\n" + quote_insert
      $rootScope.show_add_quote_to_reply_style =
        display: "none"
      $rootScope.$$phase || $rootScope.$apply()

    $rootScope.converter = initialize_markdown_converter( TemplateEngine )

    $http.get("/assets/angular-views/quote.html", {cache:$templateCache};)

])

capture_selection = ->
  #console.log "capture_selection"
  if document.all
    # get the selection for IE
    sel = document.selection
    range = sel.createRange()
    # IE's selection gives the text with linefeeds automatically
    str = range.text
    #console.log "use this string in form:\n#{str}"
    # get a node in the selection so I can find the parent comment
    node = range.parentElement()

    range.collapse(true);
    coords =
      left: range.boundingLeft
      top:  range.boundingTop;

  else
    # get the selection for other browsers
    sel = document.getSelection()
    # the text from the selection doesn't respect linefeeds, so I must manually respect linefeeds
    #console.log "conversation_select text: #{sel.toString() }"
    # turn the selection into a range
    range = sel.getRangeAt(0)
    # now get the string while respecting the linefeeds
    frag = range.cloneContents()
    child_nodes = frag.childNodes
    # get the text for each of the nodes, without formatting
    strs = ( (if node.innerHTML then node.innerHTML else node.textContent).replace(/^\s*/,'').replace(/\s*$/,'') for node in child_nodes)

    str = strs.join('\n\n').replace(/<br[^>]*>/ig, '\n')

    # get a node of the range in the selection so I can find the parent comment
    node = range.startContainer

    # get the selection coordinates
    range = range.cloneRange()
    range.collapse(true);
    coords = range.getClientRects()[0];

  if str
    # now find the parent with comment_id attr
    #node = node.parentNode until node.attributes && node.attributes.select_reference
    #select_reference = node.attributes.select_reference.value
    com_scope = angular.element(node).scope()
    img_code = com_scope.comment.sm1.match(/\/([^\/]+)\/sm\d\//)[1]
    name = "#{com_scope.comment.first_name} #{com_scope.comment.last_name}"
    [str, com_scope.comment.id, com_scope.comment.type, name, img_code, coords]
  else
    [null,null,null,null,null,null]

clear_capture_selection_button = ->
  #console.log "clear_capture_selection_button mouseup, then clear"
  doc = angular.element(document)

  rootScope = doc.scope().$root
  rootScope.show_add_quote_to_reply_style =
    display: "none"
  rootScope.$$phase || rootScope.$apply()

  doc.unbind('mouseup', clear_capture_selection_button)
  
initialize_markdown_converter = (TemplateEngine) ->
  opts = { TemplateEngine: TemplateEngine } # unless opts
  quoteTemplate = null

  #converter = new Markdown.getSanitizingConverter()
  # Since I am using hooks, I will manually hook in sanitize at the end
  converter = new Markdown.Converter();

  # Before cooking callbacks
  converter.hooks.chain "preConversion", (text) ->
    #Discourse.Markdown.trigger('beforeCook', { detail: text, opts: opts });
    #return Discourse.Markdown.textResult || text;
    return text

  # Extract quotes so their contents are not passed through markdown.
  converter.hooks.chain "preConversion", (text) ->
    extracted = Markdown.BBCode.extractQuotes(text)
    quoteTemplate = extracted.template;
    return extracted.text;


  converter.hooks.chain "postConversion", (text) ->
    # reapply quotes
    text = quoteTemplate(text) if quoteTemplate
    return Markdown.BBCode.format(text, opts);


  return converter
