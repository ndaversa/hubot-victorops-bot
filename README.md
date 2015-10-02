# Hubot Victorops Bot
A hubot script to quickly view or page the person on call in victorops

###Dependencies
- coffee-script
- node-fetch
- moment
- ical
- fuzzy
- underscore

###Configuration
- `HUBOT_VICTOROPS_POST_URL` - REST Endpoint for Victorops
- `HUBOT_VICTOROPS_TEAMS_MAP`  `\{\"ops\":\"devops\",\"data\":\"data\"\}`
- `HUBOT_VICTOROPS_TEAMS_ICAL` `\{\"devops\":\"URL_TO_ICS\",\"data\":\"URL_TO_ICS\"\}`

###Commands
`hubot page oncall <optional message>`
`hubot whois oncall`

###Setup Victorops
http://victorops.force.com/knowledgebase/articles/Integration/Alert-Ingestion-API-Documentation/
