# Add custom directives here

'use strict';

ce2_directives = angular.module('CE2.directives', ['ui.bootstrap'])

ce2_directives.directive('ceUserBar', ->
  restrict: 'A'
  templateUrl: '/assets/angular-views/signed_in.html.haml'
  replace: true
  scope: false
  controller: [ "$scope", "User", "$dialog", "$http", "$timeout"
    ($scope, User, $dialog, $http, $timeout) ->
      #$scope.user = User.get()
      $scope.user = {}
      User.get().then(
        (response)->
          console.log "ceUserBar.User.get() received response"
          $scope.user = response
      )
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
  ]
)
ce2_directives.directive('ceComment', ->
  restrict: 'A'
  templateUrl: "/assets/angular-views/comment.html.haml?t=#{new Date().getTime()}"
  replace: true
  scope: false
  controller: [ "$scope", "CommentData", "$dialog", "$http", "$timeout", "$element",
    ($scope, CommentData, $dialog, $http, $timeout, $element) ->

      $scope.edit = (comment_id) ->
        console.log "edit comment"
        $scope.$parent.newComment = (comment for comment in $scope.ConversationComments when comment.id is comment_id)[0]
      $scope.view_history = (comment_id) ->
        $scope.history = CommentData.history(comment_id)
        $scope.history_url = "/assets/angular-views/comment-history.html?t=#{$scope.timestamp}"

      $scope.hide_history = ->
        $scope.history_url = null
        delete $scope.history

      $scope.test = ->
        console.log "Clicked Comment test link"
        debugger

  ]
)

ce2_directives.directive('ceCommentForm', ->
  restrict: 'A'
  templateUrl: "/assets/angular-views/comment-form.html.haml?t=#{new Date().getTime()}"
  replace: true
  scope: false
  controller: [ "$scope", "CommentData", "AttachmentData", "$dialog", "$http", "$timeout", "$element",
    ($scope, CommentData, AttachmentData, $dialog, $http, $timeout, $element) ->

      debug = false

      $scope.newComment = { attachments: [] }
      $scope.addComment = ->
        console.log "addComment"
        if $scope.template_url
          alert 'You must save your attachment or close the attachment form'
          return
        CommentData.persist_change_to_ror 'save', $scope.newComment,
          angular.bind $scope, -> this.newComment = { attachments: [] }

      $scope.clear_form = ->
        # if there are any attachments, they need to be deleted
        # or don't clear attachments
        console.log "ceCommentForm:clear, if there are any attachments, they need to be deleted"
        $scope.newComment = { attachments: [] }

      $scope.file_selected = (element) ->
        if element.files.length > 0
          file_name = element.files[0].name
          console.log "loading file: #{file_name}" if debug
          $scope.progress_bar_message = "Loading #{file_name}"

          console.log "ceCommentForm: a file is selected, add iframe" if debug
          $scope.$root.attachment_frame_id = 1 if not $scope.$root.attachment_frame_id
          $scope.$root.attachment_frame_id += 1
          target = "attachment_upload_iframe_#{$scope.$root.attachment_frame_id}"
          form = angular.element(element.form)
          form.attr('target', target)
          form.next().replaceWith(
            "<iframe id='#{target}' name='#{target}' onload='angular.element(this).scope().iframe_loaded(this)'></iframe>" )

          $scope.$apply()

      $scope.iframe_loaded = (el) ->
            # have access to $scope here
        console.log "ceCommentForm: window.iframe_loaded, get the contents" if debug

        if not $scope.form_disabled
          console.log "ceCommentForm: a iframe is ready, submit the form" if debug
          $scope.form_disabled = true
          attach_form.submit()

        content = el.contentDocument.body.innerText
        if content
          console.log "ceCommentForm: add this data to scope: #{content}" if debug
          $scope.newComment.attachments.push angular.fromJson( content )
          $scope.newComment.attachment_ids = (att.id for att in $scope.newComment.attachments).join(', ')
          # find and clear the file input
          inputs = angular.element(attach_form).find('input')
          input for input in inputs when input.type == 'file'
          input.value = null
          angular.element(el).replaceWith('<div></div>')
          $scope.progress_bar_message = null
          $scope.form_disabled = false
          $scope.$apply()

      $scope.delete_attachment = (id) ->
        console.log "delete attachment id: #{id}" if debug
        AttachmentData.delete_attachment(id).then(
          (response)->
            console.log "AttachmentData.delete_attachment received response" if debug
            # update the scope data based on response.data
            $scope.newComment.attachments = (att for att in $scope.newComment.attachments when att.id != id)
            $scope.newComment.attachment_ids = (att.id for att in $scope.newComment.attachments).join(', ')
            console.log "AttachmentData.delete_attachment updated scope variables" if debug
        ,
        (reason) ->
          console.log "AttachmentData.delete_attachment received reason"
          dialog_scope.error_message = reason.data.error
        )

      $scope.test = ->
        console.log "ceCommentForm: test"
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

ce2_directives.directive('ceProfilePhotoForm', ->
  restrict: 'A'
  templateUrl: "/assets/angular-views/profile-photo-form.html.haml?t=#{new Date().getTime()}"
  replace: true
  scope: true
  controller: [ "$scope", "CommentData", "$dialog", "$http", "$timeout", "$element",
    ($scope, CommentData, $dialog, $http, $timeout, $element) ->

      debug = false

      $scope.file_selected = (element) ->
        if element.files.length > 0
          file_name = element.files[0].name
          console.log "ceProfilePhotoForm loading file: #{file_name}" if debug
          $scope.progress_bar_message = "Loading #{file_name}"

          console.log "ceProfilePhotoForm: a file is selected, add iframe" if debug
          $scope.$root.attachment_frame_id = 1 if not $scope.$root.attachment_frame_id
          $scope.$root.attachment_frame_id += 1
          target = "attachment_upload_iframe_#{$scope.$root.attachment_frame_id}"
          form = angular.element(element.form)
          form.attr('target', target)
          form.next().replaceWith(
            "<iframe id='#{target}' name='#{target}' onload='angular.element(this).scope().iframe_loaded(this)'></iframe>" )

          $scope.$apply()

      $scope.iframe_loaded = (el) ->
        # have access to $scope here
        console.log "ceProfilePhotoForm: window.iframe_loaded, get the contents" if debug

        if not $scope.form_disabled
          console.log "ceProfilePhotoForm: iframe is ready, submit the form" if debug
          $scope.form_disabled = true
          profile_photo_form.submit()

        content = el.contentDocument.body.innerText
        if content
          console.log "ceProfilePhotoForm: add this data to scope: #{content}" if debug
          $scope.user.small_photo_url = angular.fromJson(content).small_photo_url
          # find and clear the file input
          inputs = angular.element(profile_photo_form).find('input')
          input for input in inputs when input.type == 'file'
          input.value = null
          angular.element(el).replaceWith('<div></div>')
          $scope.progress_bar_message = null
          $scope.form_disabled = false
          $scope.$apply()
  ]
)