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

])

ce2_app.run( ['$rootScope', '$state', '$stateParams', "Issue", ($rootScope,   $state,   $stateParams, Issue) ->
  $rootScope.$state = $state
  $rootScope.$stateParams = $stateParams
  $rootScope.CSRF = document.querySelectorAll('meta[name="csrf-token"]')[0].getAttribute('content')
  $rootScope.issue = Issue.data
  $rootScope.autoGrow = (oField) ->
    if oField.scrollHeight > oField.clientHeight
      oField.style.height = oField.scrollHeight + "px"

])


