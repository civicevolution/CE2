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
            $scope.user =
              email: 'alice@civicevolution.org'
              password: 'aaaaaaaa'
              remember_me: 1
            $scope.submit_sign_in = (user) ->
              console.log "Submit by calling User.sign_in with credentials: #{user.email}/#{user.password}"
              $scope.error_message = null
              User.sign_in($scope, user, dialog)
            $scope.cancel = ->
              dialog.close()
        )
        dialog.open()

      $scope.sign_out = ->
        User.sign_out()
      $scope.sign_up = ->
        console.log "open sign up form"
        dialog = $dialog.dialog(
          backdrop: true
          keyboard: false
          backdropClick: false
          templateUrl: '/assets/angular-views/signup_form.html.haml'
          controller: ->
            # for testing
            $scope.user =
              first_name: 'Test'
              last_name: 'User'
              email: 'test@civicevolution.org'
              password: 'aaaaaaaa'
              password_confirmation: 'aaaaaaaa'
            $scope.submit_sign_up = (user) ->
              console.log "Submit by calling User.sign_up with data: #{user.name}/#{user.email}/#{user.password}"
              $scope.error_messages = null
              User.sign_up($scope, user, dialog)
            $scope.cancel = ->
              dialog.close()
        )
        dialog.open()
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

ce2_directives.directive('ceConversation', ->
  restrict: 'A'
  templateUrl: '/assets/angular-views/conversation.html.haml'
  replace: true
  controller: [ "$scope", "CommentData", "$dialog", "$http", "$timeout"
    ($scope, CommentData, $dialog, $http, $timeout) ->
      CommentData.conversation(1).then (response) ->
        # when the promise is fulfilled, set the arrays to $scope for display
        # and set the arrays as properties on the service for they can be updated
        # by firebase updates and still be bound to the view for this directive
        $scope.SummaryComments = CommentData.SummaryComment_array = response.summary_comments
        $scope.ConversationComments = CommentData.ConversationComment_array = response.conversation_comments
        $scope.question = CommentData.question = response.question
      #$scope.newComment =
      #  text: "This is a test comment #{ Date() }"

      $scope.comment_attachments = []
      $scope.addComment = ->
        CommentData.persist_change_to_ror 'save', $scope.newComment,
          angular.bind $scope, -> this.newComment = {}
      $scope.edit = (comment_id) ->
        $scope.newComment = (comment for comment in $scope.ConversationComments when comment.id is comment_id)[0]
      $scope.view_history = (comment_id) ->
        $scope.history = CommentData.history(comment_id)

      $scope.clear_form = ->
        $scope.newComment = {id: null, text: null}

      $scope.toggle_attachment_form = ->
        #console.log "toggle_attachment_form"
        if $scope.template_url
          $scope.toggle_attachment_label = "Show attachment form"
          $scope.template_url = null
          $scope.attachment_iframe_url = null
        else
          $scope.toggle_attachment_label = "Hide attachment form"
          $scope.template_url = '/assets/angular-views/attachment_form.html'
          $scope.timestamp = new Date().getTime()
      $scope.toggle_attachment_label = "Show attachment form"
      $scope.template_url = null

      $scope.attachment_iframe_url = null
      $scope.upload_attachment = ->
        event.preventDefault() if event
        #console.log "Upload the attachment now"
        $scope.attachment_iframe_url = '/assets/angular-views/attachment_iframe.html'

      $scope.iframe_directive_loaded = ->
        #console.log "iframe directive is loaded, submit the form"
        attach_form.submit()

      window.iframe_loaded = (el) ->
        # have access to $scope here
        #console.log "window.iframe_loaded, get the contents"
        content = el.contentDocument.body.innerText
        if content
          #console.log "add this data to scope: #{content}"
          $scope.comment_attachments.push angular.fromJson( content )
          $scope.toggle_attachment_form()
          $scope.$apply()

      $scope.test = ->
        console.log "Clicked test link"

  ]
)

ce2_directives.directive('ceCsrf', ->
  restrict: 'A'
  replace: false
  transclude: true
  templateUrl: '/assets/angular-views/csrf-form-inputs.html.haml'
)