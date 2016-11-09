# Hubot Victorops Bot
A hubot script to quickly view or page the person on call in VictorOps

###Dependencies
- coffee-script
- node-fetch
- moment
- ical
- fuzzy
- underscore

###Configuration
- `HUBOT_VICTOROPS_POST_URL` - REST Endpoint for VictorOps
- `HUBOT_VICTOROPS_TEAMS_MAP`  `\{\"routing_key1\":\"team1\",\"routing_key2\":\"team2\"\}`
- `HUBOT_VICTOROPS_TEAMS_ICAL` `\{\"team1\":\"URL_TO_ICS\",\"team2\":\"URL_TO_ICS\"\}`

The specific configuration can be taken from VictorOps's portal -> Settings -> Integration -> Routing Keys.
You can only page oncall inside channels. Ensure that you map your routing key names to desired slack channel names.

###Commands
- `hubot page oncall <optional message>`
- `hubot whois oncall`

###Setup VictorOps
http://victorops.force.com/knowledgebase/articles/Integration/Alert-Ingestion-API-Documentation/
