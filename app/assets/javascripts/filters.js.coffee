# Add custom filters here

'use strict';

ce2_filters = angular.module('CE2.filters',[])

ce2_filters.filter('summary_comments', ->
  return (comments) ->
    if comments
      comments = (comment for comment in comments when comment.type is "SummaryComment")
)

ce2_filters.filter('conversation_comments', ->
  return (comments) ->
    if comments
      comments = (comment for comment in comments when comment.type is "ConversationComment")
)

ce2_filters.filter('from_now', ->
  return (date) ->
    moment(date).fromNow()
)

