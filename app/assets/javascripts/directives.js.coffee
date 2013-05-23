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

      $scope.newComment = { text: 'text set in ceConversation', attachments: [] }
      $scope.addComment = ->
        if $scope.template_url
          alert 'You must save your attachment or close the attachment form'
          return
        CommentData.persist_change_to_ror 'save', $scope.newComment,
          angular.bind $scope, -> this.newComment = {}
      #$scope.edit = (comment_id) ->
      #  $scope.newComment = (comment for comment in $scope.ConversationComments when comment.id is comment_id)[0]
      #$scope.view_history = (comment_id) ->
      #  $scope.history = CommentData.history(comment_id)

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
ce2_directives.directive('ceComment', ->
  restrict: 'A'
  templateUrl: '/assets/angular-views/comment.html.haml'
  replace: true
  scope: false
  controller: [ "$scope", "CommentData", "$dialog", "$http", "$timeout", "$element",
    ($scope, CommentData, $dialog, $http, $timeout, $element) ->
      #CommentData.conversation(1).then (response) ->
      #  # when the promise is fulfilled, set the arrays to $scope for display
      #  # and set the arrays as properties on the service for they can be updated
      #  # by firebase updates and still be bound to the view for this directive
      #  $scope.SummaryComments = CommentData.SummaryComment_array = response.summary_comments
      #  $scope.ConversationComments = CommentData.ConversationComment_array = response.conversation_comments
      #  $scope.question = CommentData.question = response.question
      ##$scope.newComment =
      ##  text: "This is a test comment #{ Date() }"

      #$scope.newComment = { attachments: [] }
      #$scope.addComment = ->
      #  if $scope.template_url
      #    alert 'You must save your attachment or close the attachment form'
      #    return
      #  CommentData.persist_change_to_ror 'save', $scope.newComment,
      #    angular.bind $scope, -> this.newComment = {}
      $scope.edit = (comment_id) ->
        console.log "edit comment"
        $scope.$parent.newComment = (comment for comment in $scope.ConversationComments when comment.id is comment_id)[0]
      $scope.view_history = (comment_id) ->
        $scope.history = CommentData.history(comment_id)
        $scope.history_url = "/assets/angular-views/comment-history.html?t=#{$scope.timestamp}"

      $scope.hide_history = ->
        $scope.history_url = null
        delete $scope.history

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
        console.log "Clicked Comment test link"
        debugger

  ]
)

ce2_directives.directive('ceCsrf', ->
  restrict: 'A'
  replace: false
  transclude: true
  templateUrl: "/assets/angular-views/csrf-form-inputs.html?t=#{new Date().getTime()}"
)


ce2_directives.directive('ceRatingSlider', ->
  restrict: 'A'
  replace: true
  scope: false
  templateUrl: "/assets/angular-views/rating-slider.html?t=#{new Date().getTime()}"
  controller: [ "$scope", "CommentData", ($scope, CommentData) ->
    $scope.persist_rating = ->
      #console.log "scope.persist_rating call on CommentData id: #{$scope.comment.id} with rating: #{$scope.rating}"
      CommentData.persist_rating_to_ror($scope.comment.id, $scope.comment.my_rating).then (response) ->
        $scope.comment.ratings_cache = response.data
  ]

  link: (scope, element, attrs) ->
    #console.log "link function to draw rating slider with scope: #{scope.$id} and comment.id: #{scope.comment.id}"

    scope.$watch('comment.ratings_cache', (oldValue, newValue) ->
      ctx = element.find('canvas')[0].getContext('2d');
      grapher = new window.Graph();
      grapher.draw_rating_results(ctx, scope.comment.ratings_cache, scope.comment.my_rating);
    , true)

    mouse_out_box = element
    canvas = mouse_out_box.find('canvas')
    mouse_binding_box = canvas.parent()
    handle = mouse_binding_box.find('div')
    debug = false
    if scope.comment.my_rating
      handle.css( 'left', "#{scope.comment.my_rating/100*350-5}px" )
    else
      handle.css( 'left', "#{50/100*350-5}px" )
    width = offset = null
    handle_width = 10

    mouseDown = false;

    mouse_binding_box.bind "mousedown", (evt) ->
      mouseDown = true
      if not width
        padding = 20
        width = _.width(mouse_binding_box[0]) - padding
        console.log "width: #{width}" if debug
      if not offset
        offset = _.offset(mouse_binding_box[0]).left
        console.log "offset: #{offset}" if debug
      calculate_position(evt)

    # TODO throttle the calls made by mouse move
    #element.bind('mousemove', _.throttle(_pd( (evt) ->
    #  return if not mouseDown
    #  calculate_position(evt)
    #),
    #25))

    mouse_binding_box.bind('mousemove', (evt) ->
      return if not mouseDown
      calculate_position(evt)
    )

    mouse_binding_box.bind "mouseup", (event) ->
      mouseDown = false
      persist_rating_now()

    # catch mouse leaving rating while still down which keeps rating still active
    mouse_out_box.bind "mouseout", (event) ->
      if event.toElement == element[0]
        if mouseDown
          mouseDown = false
          persist_rating_now()

    calculate_position = (evt) ->
      pageX = if evt.pageX
        evt.pageX
      else if evt.clientX
        evt.clientX
      else
        evt.originalEvent.touches[0].pageX

      diff = pageX - offset

      scope.comment.my_rating = if diff < 0
        diff = 0 if diff < 0
        0
      else if diff > width
        diff = width + 12 if diff > width + 12
        100
      else
        Math.round( diff / width * 100 )

      handle.css( 'left', "#{diff-5}px" )
      console.log "pageX: #{pageX}, diff: #{diff}, scope.rating: #{scope.comment.my_rating}%" if debug
      scope.$apply()

    persist_rating_now = ->
      #console.log "persist rating now with scope: #{scope.$id}"
      scope.$apply( ->
        scope.persist_rating()
      )


)

