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


ce2_app = angular.module("CE2", ["ngResource","CE2.services", "firebase"] )

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


#ce2_app.controller( "TestCtrl", [ "$scope", "resolved_data", ($scope, resolved_data ) ->	
ce2_app.controller( "TestCtrl", [ "$scope", "resolved_data", ($scope, resolved_data ) ->	
  $scope.name = resolved_data.name
  $scope.my_var = resolved_data.my_var
  $scope.test = ->
      console.log("Hello from test");
] )

ce2_app.config ($routeProvider) ->
	$routeProvider.
		when('/pizza', {template: 'String of html is served like pizza'}).
		when('/convo', {templateUrl: '/assets/angular-views/convo.html'}).
		when('/convoX', {
		  templateUrl: 'simple_temps/temp1.html',
		  controller: 'TestCtrl'
		}).
		when('/convoY', {
		  templateUrl: 'simple_temps/temp1.html',
		  controller: 'TestCtrl',
		  resolve: {
  		    resolved_data: ->
  		      console.log("inside resolve");
  		      my_var: 'my data from routing convoY' 
  		      name: 'BrianY (resolved_data)'
  		}
		}).
		when('/convoZ', {
		  templateUrl: 'simple_temps/temp1.html',
		  controller: 'TestCtrl',
		  resolve: {
  		    resolved_data: ->
  		      console.log("inside resolve");
  		      my_var: 'my data from routing convoZ' 
  		      name: 'BrianZ (resolved_data)'
  		}
		}).
		
		otherwise( { redirectTo: '/' } )

