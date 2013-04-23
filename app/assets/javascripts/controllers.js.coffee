# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

bootstrap_CE2 = ->
	#console.log "In bootstrap_CE2"
	try
		angular.module('firebase')
		angular.bootstrap(document,["CE2"])
	catch error
		setTimeout bootstrap_CE2, 50
bootstrap_CE2()


ce2_app = angular.module("CE2", ["ngResource","CE2.services", "firebase", 'ui.compat'] )

ce2_app.config ($httpProvider) ->
	$httpProvider.defaults.headers.common["X-CSRF-TOKEN"] = 
		document.querySelectorAll('meta[name="csrf-token"]')[0].getAttribute('content')

ce2_app.controller( "ConversationCtrl", [ "$scope", "CommentData", ($scope, CommentData) ->	

	$scope.comments = CommentData.comments
		
	$scope.addComment = ->
		CommentData.persist_change_to_ror 'save', $scope.newComment, 
			angular.bind $scope, -> this.newComment = {}
		
	$scope.like = ->
		liked = if @comment.liked? && @comment.liked then false else true
		CommentData.persist_change_to_ror 'update', { id: @comment.id, liked: liked }, -> 
			console.log "doing the controller's callback for like comment"
		
	$scope.delete = ->
		CommentData.persist_change_to_ror 'delete', @comment
		
] )		


ce2_app.controller( "AngularFireCtrl", [ 'angularFireCollection', (angularFireCollection) ->	
	url = 'https://civicevolution.firebaseio.com/issues/7/updates'
	# don't attach to the view, just initialize it so it will trigger on updates
	angularFireCollection url
] )


ce2_app.controller( "TestCtrl", [ "$scope", "resolved_data", ($scope, resolved_data ) ->	
  $scope.name = resolved_data.name
  $scope.my_var = resolved_data.my_var
  $scope.test = ->
      console.log("Hello from test");
] )




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
      .state('about', {
        url: '/about',
        templateProvider:
          [        '$timeout', ($timeout) ->
            $timeout -> 
              "Hello <i>world</i>" 
            , 100
          ]
      })
      .state('state1', {
        url: '/state1',
        templateProvider:
          [        '$timeout', ($timeout) ->
            $timeout -> 
              "I am now in state1" 
            , 100
          ]
      })
      .state('state2', {
        url: '/state2',
        templateUrl: '/assets/angular-views/state2.html'
      })
      .state('state3', {
        url: '/state3',
        templateUrl: '/assets/angular-views/state3.html'
        controller: ($scope, $state, $timeout) ->
          $scope.user = 'Brian Sullivan'
          $scope.goto_state1 = ->
            console.log "hey, I want to go to state1"
            $state.transitionTo('state1')
            $timeout ->
              $state.transitionTo('state2')
            , 2000
      })

      
  ])

ce2_app.run( ['$rootScope', '$state', '$stateParams', ($rootScope,   $state,   $stateParams) ->
  $rootScope.$state = $state
  $rootScope.$stateParams = $stateParams
])

