# Add custom directives here

'use strict';

ce2_directives = angular.module('CE2.directives', ['ui.bootstrap'])

ce2_directives.directive('ceUserBar', ->
  restrict: 'A'
  templateUrl: '/assets/angular-views/signed_in.html.haml'
  replace: true
  controller: [ "$scope", "UserAppData", "$dialog",
    ($scope, UserAppData, $dialog) ->
      $scope.user = UserAppData.user
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
            dialog.close("#{signin.email}/#{signin.password}")
          $scope.cancel = ->
            dialog.close()
        )
        dialog.open().then( (result) ->
          alert "dialog closed with result: #{result}" if result
        )


      $scope.sign_out = ->
        console.log "sign out"
      $scope.sign_up = ->
        console.log "sign up"
      $scope.edit_profile = ->
        console.log "edit profile"
  ]
)
