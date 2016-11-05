# Description:
# Quickly view or page the person on call in victorops
#
# Dependencies:
# - coffee-script
# - node-fetch
# - moment
# - ical
# - fuzzy
# - underscore
#
# Configuration:
# HUBOT_VICTOROPS_POST_URL - REST Endpoint for Victorops
# HUBOT_VICTOROPS_TEAMS_MAP  `\{\"ops\":\"devops\",\"data\":\"data\"\}`
# HUBOT_VICTOROPS_TEAMS_ICAL `\{\"devops\":\"URL_TO_ICS\",\"data\":\"URL_TO_ICS\"\}`
#
# Commands:
#   hubot page oncall <optional message>
#   hubot whois oncall
#
# Author:
#   ndaversa

_ = require 'underscore'
fetch = require 'node-fetch'
moment = require 'moment'
ical = require 'ical'
fuzzy = require 'fuzzy'

module.exports = (robot) ->
  users = robot.brain.users() or @robot.adapter.client.rtm.dataStore.users
  url = process.env.HUBOT_VICTOROPS_POST_URL
  teams = JSON.parse process.env.HUBOT_VICTOROPS_TEAMS_MAP
  calendars = JSON.parse process.env.HUBOT_VICTOROPS_TEAMS_ICAL

  getRoom = (context) ->
    room = robot.adapter.client.rtm.dataStore.getChannelOrGroupByName context.message.room
    room = robot.adapter.client.rtm.dataStore.getChannelGroupOrDMById context.message.room unless room
    room

  parseJSON = (response) ->
    return response.json()

  checkStatus = (response) ->
    if response.status >= 200 and response.status < 300
      return response
    else
      error = new Error(response.statusText)
      error.response = response
      throw error

  invalidChannel = (msg) ->
    channels = []
    for team, key of teams
      channel = robot.adapter.client.getChannelGroupOrDMByName team
      channels.push " <\##{channel.id}|#{channel.name}>" if channel
    return msg.reply "You can only page for oncall in one of the following project channels: #{channels}"

  lookupUser = (name) ->
    name = name.replace '.', ' ' if name?
    users = _(users).keys().map (id) ->
      user = users[id]
      id: id
      name: user.real_name || user.name

    results = fuzzy.filter name, users, extract: (user) -> user.name
    if results?.length >= 1
      return "<@#{results[0].original.id}>"
    else
      return name

  whoIsOncall = (team, cb) ->
    now = moment()
    calendar = calendars[team]
    ical.fromURL calendar, {}, (err, data) ->
      events = _(data).keys().map (id) ->
        event = data[id]
        start: moment event.start
        end: moment event.end
        summary: event.summary
        id: id
      .filter (event) -> now.isBetween event.start, event.end

      if events.length is 1
        oncall = events[0]
      else
        events = events.filter (event) -> event.summary.indexOf('OVERRIDE') > -1
        if events.length is 1
          oncall = events[0]

      if oncall
        [ __, person ] = oncall.summary.match /(?:OVERRIDE:\s)?(.*)/
      cb person

  robot.respond /page on\s?call(?:\s+(.*))?/, (msg) ->
    [ __, message ] = msg.match
    room = getRoom msg
    team = teams[room.name]
    return invalidChannel msg unless team

    whoIsOncall team, (person) ->
      if person
        fetch "#{url}#{team}",
          method: "POST"
          body: JSON.stringify
           entity_id: "slack-ops"
           message_type: "critical"
           entity_display_name: "Paged by @#{msg.message.user.name} in ##{room.name}"
           state_message: message
        .then (res) ->
          checkStatus res
        .then (res) ->
          parseJSON res
        .then (json) ->
          msg.reply "Paged #{lookupUser person} whom is on call for the `#{team}` team in victorops"
        .catch (error) ->
          console.log "*[Error]* #{error}"
          msg.reply "I have failed at paging #{lookupUser person}. I am shamed"
      else
        msg.reply "I can't determine who is on call, please contact your friendly administrator"

  robot.respond /who\s?is on\s?call/, (msg) ->
    room = getRoom msg
    team = teams[room.name]
    return invalidChannel msg unless team

    whoIsOncall team, (person) ->
      if person
        msg.reply "#{lookupUser person} is on duty for the `#{team}` team"
      else
        msg.reply "I can't determine who is on call, please contact your friendly administrator"
