# Add custom directives here

'use strict';

ce2_directives = angular.module('CE2.directives', ['ui.bootstrap'])

ce2_directives.directive('ceUserBar', ->
  restrict: 'A'
  templateUrl: '/assets/angular-views/signed_in.html.haml'
  replace: true
  controller: [ "$scope", "User", "$dialog", "$http", "$timeout"
    ($scope, User, $dialog, $http, $timeout) ->
      $scope.user = User.get()
      $scope.sign_in = ->
        console.log "open sign in form"
        dialog = $dialog.dialog(
          backdrop: true
          keyboard: true
          backdropClick: true
          templateUrl: '/assets/angular-views/signin_form.html.haml'
          controller: ->
            # for testing
            $scope.signin =
              email: 'alice@civicevolution.org'
              password: 'aaaaaaaa'
            $scope.submit_sign_in = (signin) ->
              console.log "Submit by calling User.sign_in with credentials: #{signin.email}/#{signin.password}"
              User.sign_in(signin)
              #dialog.close("#{signin.email}/#{signin.password}")
            $scope.cancel = ->
              dialog.close()
        )
        dialog.open()

      $scope.sign_out = ->
        User.sign_out()
      $scope.sign_up = ->
        User.sign_up()
      $scope.edit_profile = ->
        User.edit_profile()
  ]
)

ce2_directives.directive('ceFocus', [ "$timeout", ($timeout) ->
  link: ( scope, element, attrs, controller) ->
    $timeout ->
      element[0].focus()
    , 100

])
