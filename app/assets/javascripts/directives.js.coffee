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

      $scope.newComment = { attachments: [] }
      $scope.addComment = ->
        if $scope.template_url
          alert 'You must save your attachment or close the attachment form'
          return
        CommentData.persist_change_to_ror 'save', $scope.newComment,
          angular.bind $scope, -> this.newComment = {}
      $scope.edit = (comment_id) ->
        $scope.newComment = (comment for comment in $scope.ConversationComments when comment.id is comment_id)[0]
      $scope.view_history = (comment_id) ->
        $scope.history = CommentData.history(comment_id)

      $scope.clear_form = ->
        $scope.newComment = { attachments: [] }

      $scope.toggle_attachment_form = ->
        #console.log "toggle_attachment_form"
        if $scope.template_url
          $scope.toggle_attachment_label = "Show attachment form"
          $scope.template_url = null
          $scope.attachment_iframe_url = null
        else
          $scope.toggle_attachment_label = "Hide attachment form"
          $scope.timestamp = new Date().getTime()
          $scope.template_url = "/assets/angular-views/attachment_form.html?t=#{$scope.timestamp}"

      $scope.toggle_attachment_label = "Show attachment form"
      $scope.template_url = null

      $scope.attachment_iframe_url = null
      $scope.upload_attachment = ->
        if (event.preventDefault)
          event.preventDefault()
        else
          event.returnValue = false # ie
        #console.log "Attach the iframe for submitting the file upload"
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
          $scope.newComment.attachments.push angular.fromJson( content )
          $scope.newComment.attachment_ids = (att.id for att in $scope.newComment.attachments).join(', ')
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
  templateUrl: "/assets/angular-views/csrf-form-inputs.html?t=#{new Date().getTime()}"
)


ce2_directives.directive('ceRatingSlider', ->
  controller: [ "$scope", ($scope) ->
    $scope.rating = 50
  ]
  link: (scope, element, attrs) ->
    element = element
    bar = element.find('span')
    
    # Scope/DOM elements that are not initialized out of game.
    width = offset = null

    mouseDown = false;

    element.bind "mousedown", (evt) ->
      mouseDown = true
      if not width
        padding = 20
        width = _.widthCE(element[0]) - padding # 704 # element.width()
        console.log "width: #{width}"  
      if not offset
        offset = _.offset(bar).left
      calculate_position(evt)

    #element.bind('mousemove', _.throttle(_pd( (evt) ->
    #  return if not mouseDown
    #  calculate_position(evt)
    #),
    #25))

    element.bind('mousemove', (evt) ->
      return if not mouseDown
      calculate_position(evt)
    )

    element.bind "mouseup", (event) ->
      mouseDown = false

    calculate_position = (evt) ->
      if evt.pageX
        diff = evt.pageX - offset
      else if evt.clientX
        diff = evt.clientX - offset
      else
        diff = evt.originalEvent.touches[0].pageX - offset

      if diff < 0
        scope.rating = 0
      else if diff > width
        scope.rating = 100
      else
        scope.rating = Math.round( diff / width * 100 )

      bar.css( { width: "#{scope.rating}%"})
      scope.$apply()
)