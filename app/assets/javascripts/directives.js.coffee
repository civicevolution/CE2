# Add custom directives here

'use strict';

ce2_directives = angular.module('CE2.directives', ['ui.bootstrap'])

ce2_directives.directive('ceUserBar', ->
  restrict: 'A'
  templateUrl: '/assets/angular-views/signed_in.html.haml'
  replace: true
  controller: [ "$scope", "UserAppData", "$dialog", "$http", "User",
    ($scope, UserAppData, $dialog, $http, User) ->
      $scope.user = User.get()
      $scope.sign_in = ->
        console.log "sign in"
        dialog = $dialog.dialog(
          backdrop: true
          keyboard: true
          backdropClick: true
          templateUrl: '/assets/angular-views/signin_form.html.haml'
          controller: ->
          $scope.submit_sign_in = (signin) ->
            console.log "Process sign in submit"
            UserAppData.sign_in()
            #dialog.close("#{signin.email}/#{signin.password}")
          $scope.cancel = ->
            dialog.close()
        )
        dialog.open().then( (result) ->
          alert "dialog closed with result: #{result}" if result
        )


      $scope.sign_out = ->
        UserAppData.sign_out()
      $scope.sign_up = ->
        console.log "sign up"
        debugger
      $scope.edit_profile = ->
        console.log "edit profile"
  ]
)

ce2_directives.directive('ceFocus', [ "$timeout", ($timeout) ->
  link: ( scope, element, attrs, controller) ->
    $timeout ->
      element[0].focus()
    , 100

])
