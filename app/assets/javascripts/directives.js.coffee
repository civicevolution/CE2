# Add custom directives here

'use strict';

ce2_directives = angular.module('CE2.directives', ['ui.bootstrap'])

ce2_directives.directive('ceUserBar', ->
  restrict: 'A'
  templateUrl: '/assets/angular-views/user-bar.html.haml'
  replace: true
  scope: false
  controller: [ "$scope", "User", "$dialog", "$http", "$timeout", "$state" ,
    ($scope, User, $dialog, $http, $timeout, $state) ->
      #$scope.user = User.get()
      $scope.user = {}
      User.get().then(
        (response)->
          #console.log "ceUserBar.User.get() received response"
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
        $state.transitionTo('edit-profile')
      $scope.test = ->
        console.log "CeUserBar test"
        debugger
  ]
)

ce2_directives.directive('ceFocus', [ "$timeout", ($timeout) ->
  link: ( scope, element, attrs, controller) ->
    $timeout ->
      element[0].focus()
    , 100

])


ce2_directives.directive('ceQuestion', ->
  restrict: 'A'
  templateUrl: "/assets/angular-views/question.html?t=#{new Date().getTime()}"
  replace: true
)

ce2_directives.directive('ceConversation', ->
  restrict: 'A'
  templateUrl: '/assets/angular-views/conversation.html.haml'
  replace: true
  controller: [ "$scope", "ConversationData", "FirebaseService",
    ($scope, ConversationData, FirebaseService) ->
      ConversationData.conversation($scope.conversation.id).then (response) ->
        # when the promise is fulfilled, set the arrays to $scope for display
        # and set the arrays as properties on the service for they can be updated
        # by firebase updates and still be bound to the view for this directive
        $scope.SummaryComments = response.summary_comments
        $scope.ConversationComments = response.conversation_comments

        # Subscribe to updates for this data
        url = "https://civicevolution.firebaseio.com/issues/1/conversations/#{$scope.conversation.id}/updates/"
        FirebaseService.initialize_source(url, response.firebase_token)

        # register the listeners for the firebase updates
        $scope.$on( 'ConversationComment_update', (event, data) ->
          #console.log "received broadcast ConversationComment_update"
          FirebaseService.process_update($scope.ConversationComments, data)
        )
        $scope.$on( 'SummaryComment_update', (event, data) ->
          #console.log "received broadcast SummaryComment_update"
          FirebaseService.process_update($scope.SummaryComments, data)
        )
  ]
)
ce2_directives.directive('ceComment', ->
  restrict: 'A'
  templateUrl: "/assets/angular-views/comment.html.haml?t=#{new Date().getTime()}"
  replace: true
  scope: false
  priority: 100
  controller: [ "$scope", "CommentData",
    ($scope, CommentData) ->

      $scope.edit = (comment_type, comment_id) ->
        console.log "edit comment"
        $scope.edit_mode = true
        $scope.newComment = angular.copy( (comment for comment in $scope["#{comment_type}s"] when comment.id is comment_id)[0] )
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

ce2_directives.directive('ceCommentForm', [ "$timeout", ($timeout) ->
  restrict: 'A'
  templateUrl: "/assets/angular-views/comment-form.html.haml?t=#{new Date().getTime()}"
  replace: true
  scope: true
  link: (scope, element, attrs) ->
    #console.log "link function for ceCommentForm with scope: #{scope.$id}"
    scope.newComment.conversation_id = scope.conversation.id
    scope.newComment.type = attrs.type
    $timeout ->
      scope.autoGrow(element.find('textarea')[0])
    , 100

  controller: [ "$scope", "CommentData", "AttachmentData",
    ($scope, CommentData, AttachmentData) ->

      debug = false

      $scope.newComment = { attachments: [] } if not ($scope.newComment && $scope.newComment.id)
      $scope.addComment = ->
        console.log "addComment"
        if $scope.template_url
          alert 'You must save your attachment or close the attachment form'
          return
        CommentData.persist_change_to_ror 'save', $scope.newComment,
          angular.bind $scope, ->
            this.newComment.attachments = []
            this.newComment.id = null
            this.newComment.text = null
            $scope.$parent.$parent.edit_mode = false

      $scope.clear_form = ->
        # if there are any attachments, they need to be deleted
        # or don't clear attachments
        console.log "ceCommentForm:clear, if there are any attachments, they need to be deleted"
        $scope.newComment = { attachments: [] }

      $scope.cancel_edit = ->
        #console.log "cancel the comment edit"
        $scope.$parent.$parent.edit_mode = false

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
          angular.element(el).parent().find('form')[0].submit()

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
])

ce2_directives.directive('ceCsrf', ->
  restrict: 'A'
  replace: false
  transclude: true
  templateUrl: "/assets/angular-views/csrf-form-inputs.html?t=#{new Date().getTime()}"
)


ce2_directives.directive('ceRatingSlider', [ "$document", ($document) ->
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

    canvas = element.find('canvas')
    mouse_binding_box = canvas.parent()
    handle = mouse_binding_box.find('div')
    debug = false
    if scope.comment.my_rating
      handle.css( 'left', "#{scope.comment.my_rating/100*350-9}px" )
    else
      handle.css( 'left', "#{50/100*350-9}px" )
    width = offset = null

    mouse_binding_box.bind "mousedown", ($event) ->
      angular.element(document.body).addClass('drag_in_process')
      if not width
        padding = 20
        width = _.width(mouse_binding_box[0]) - padding
        console.log "width: #{width}" if debug
      if not offset
        offset = _.offset(mouse_binding_box[0]).left
        console.log "offset: #{offset}" if debug
      calculate_position($event)
      $document.bind('mousemove', calculate_position)
      $document.bind('mouseup', mouseup)

    # TODO throttle the calls made by mouse move
    #element.bind('mousemove', _.throttle(_pd( (evt) ->
    #  return if not mouseDown
    #  calculate_position(evt)
    #),
    #25))

    mouseup = () ->
      $document.unbind('mousemove', calculate_position)
      $document.unbind('mouseup', mouseup)
      angular.element(document.body).removeClass('drag_in_process')
      persist_rating_now()

    calculate_position = ($event) ->
      pageX = if $event.pageX
        $event.pageX
      else if $event.clientX
        $event.clientX
      else
        $event.originalEvent.touches[0].pageX

      diff = pageX - offset

      scope.comment.my_rating = if diff < 0
        diff = 0 if diff < 0
        1
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
])

ce2_directives.directive('ceProfilePhotoForm', ->
  restrict: 'A'
  templateUrl: "/assets/angular-views/profile-photo-form.html.haml?t=#{new Date().getTime()}"
  replace: true
  scope: true
  controller: [ "$scope",
    ($scope) ->

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
          $scope.user.sm1 = angular.fromJson(content).sm1
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


ce2_directives.directive('ceSortable', [ "$document", "$timeout",
  ($document, $timeout) ->
    restrict: 'A'
    priority: 500
    scope: true
    link: (scope, elm, attrs) ->
      startX = startY = initialMouseX = initialMouseY = mouseY = 0
      placeholder = dragged = placeholder_upper = placeholder_lower = {}

      elm.addClass('ce-sortable-item')
      elm.wrap('<div class="ce-sortable-item-carrier"></div>')
      item_carrier = elm.parent();
      
      if typeof item_carrier.parent().attr('ng-repeat')
        #console.log "Build up item using the ng-repeat parent element"
        item_pair = item_carrier.parent()
        item_pair.addClass("ce-sortable-item-pair")
      else
        #console.log "Build up original item"
        item_carrier.wrap('<div class="ce-sortable-item-pair"></div>')
        item_pair = item_carrier.parent()

      handle = angular.element('<div class="ce-sortable-handle"></div>')
      elm.append(handle)

      item_carrier.after(angular.element('<div class="ce-sortable-placeholder ce-sortable-item"></div>'))

      elm = item_carrier

      #elm.html("y: #{ elm.parent().prop('offsetTop') }")

      debug = false

      handle.bind('mousedown', ($event) ->
        angular.element(document.body).addClass('drag_in_process')
        startX = elm.parent().prop('offsetLeft')
        startY = elm.parent().prop('offsetTop')
        elm.css
          position: 'absolute'
          top:  "#{startX}px"
          #left: "#{startY}px"

        console.log "startX: #{startX}, startY: #{startY}" if debug
        initialMouseX = $event.clientX
        initialMouseY = $event.clientY
        $document.bind('mousemove', mousemove)
        $document.bind('mouseup', mouseup)
        record_current_place_holders()

        elm.next().css
          display: 'block'
          height: "#{placeholder.h}px"
          width: "#{placeholder.w}px"

        adjust_dragged($event)

        false

      )

      mousemove = ($event) ->
        #console.log "mousemove initialMouseX: #{initialMouseX}, initialMouseY: #{initialMouseY}" if debug
        adjust_dragged($event)
        calculate_offset()
        false

      mouseup = () ->
        elm.css({position: 'static', left: "#{startX}px", top: "#{startY}px"})
        $document.unbind('mousemove', mousemove)
        $document.unbind('mouseup', mouseup)
        elm.next().css({display: 'none'})
        $timeout ->
          angular.element(document.body).removeClass('drag_in_process')
        , 1000


      record_current_place_holders = ->
        old_startX = startX
        startX = elm.parent().prop('offsetLeft')
        initialMouseX += (startX - old_startX)

        old_startY = startY
        startY = elm.parent().prop('offsetTop')
        initialMouseY += (startY - old_startY)

        placeholder =
          x: startX
          y: startY
          w: elm.prop('offsetWidth')
          h: elm.prop('offsetHeight')

        nextElm = elm.parent().next()
        if nextElm.length > 0
          placeholder_lower = angular.copy(placeholder)
          placeholder_lower.y = placeholder.y + nextElm.prop('offsetHeight')
        else
          placeholder_lower = null

        prevElm = angular.element( elm.parent()[0].previousElementSibling )
        if prevElm.length > 0
          placeholder_upper = angular.copy(placeholder)
          placeholder_upper.y = placeholder.y - prevElm.prop('offsetHeight')
        else
          placeholder_upper = null

        console.log "placeholder_upper: " + ("#{key}: #{placeholder_upper[key]}" for key of placeholder_upper).join(', ') if debug
        console.log "placeholder: " + ("#{key}: #{placeholder[key]}" for key of placeholder).join(', ') if debug
        console.log "placeholder_lower: " + ("#{key}: #{placeholder_lower[key]}" for key of placeholder_lower).join(', ') if debug


      adjust_dragged = ($event) ->
        dragged =
          x: startX + $event.clientX - initialMouseX
          y: startY + $event.clientY - initialMouseY
        #elm.css { left: "#{dragged.x}px" }
        elm.css { top: "#{dragged.y}px" }

      calculate_offset = ->
        #console.log "calculate_offset"
        #console.log "PH: " + ("#{key}: #{placeholder[key]}" for key of placeholder).join(', ') + ", DR: " + ("#{key}: #{dragged[key]}" for key of dragged).join(', ') if debug
        console.log "sY: #{startY}, iY: #{initialMouseY}, mY: #{mouseY}, DR.Y: #{dragged.y}, phU.y: #{placeholder_upper?.y}, ph.y: #{placeholder?.y}, phL.y: #{placeholder_lower?.y}" if debug

        offset =
          x: (dragged.x - placeholder.x)/placeholder.w * 100
          y: (dragged.y - placeholder.y)/placeholder.h * 100
        #console.log ("#{key}: #{offset[key]}" for key of offset).join(', ')

        if offset.y > 50 && placeholder_lower
          lower_y_offset = (dragged.y - placeholder_lower.y)/placeholder.h * 100
          #console.log "check offset with placeholder_lower, offset.y: #{offset.y}, lower offset y: #{lower_y_offset}"
          if Math.abs(offset.y) > Math.abs(lower_y_offset)
            console.log "SWAP THE ELEMENT WITH THE LOWER ELEMENT" if debug
            next_elm = elm.parent().next()
            next_elm.after(elm.parent())
            placeholder.y = elm.parent().prop('offsetTop')
            record_current_place_holders()

        else if offset.y < -50 && placeholder_upper
          upper_y_offset = (dragged.y - placeholder_upper.y)/placeholder.h * 100
          #console.log "check offset with placeholder_upper, offset.y: #{offset.y}, lower offset y: #{upper_y_offset}"
          if Math.abs(offset.y) > Math.abs(upper_y_offset)
            console.log "SWAP THE ELEMENT WITH THE UPPER ELEMENT" if debug
            prev_elm = angular.element( elm.parent()[0].previousElementSibling )
            elm.parent().after(prev_elm)
            placeholder.y = elm.parent().prop('offsetTop')
            record_current_place_holders()

])
