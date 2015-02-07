Messages = new Meteor.Collection 'messages'
Messages._createCappedCollection 100 * 1024, 10

sendMessage = (type, data) ->
  Messages.insert
    ts: new MongoInternals.MongoTimestamp 0, 0
    type: type
    data: data

setupMessages = ->
  initializing = true
  # We send a startup message for which we then wait to read. After
  # we read it, we know that we should start processing messages.
  randomId = Random.id()
  sendMessage 'startup', randomId
  # And now we start processing all messages
  Messages.find({}, tailable: true).observeChanges
    added: (id, fields) ->
      if fields.type is 'startup' and fields.data is randomId
        initializing = false
        return

      return if initializing

      # We do not do anything, this is just so that there is a tailable observe in the background.
      #console.log "Message", fields

Meteor.startup ->
  setupMessages()

  Meteor.setInterval ->
    sendMessage 'test', new Date()
  ,
    1000 # ms

Meteor.startup ->
  TestCollection.remove {}

  Meteor.setInterval ->
    TestCollection.insert
      test: new Date()
  ,
    100 # ms

Meteor.publish null, ->
  handle = TestCollection.find({}).observeChanges
    added: (id, fields) =>
      console.log id, fields
      @added 'test', id, fields
      @removed 'test', id

  @onStop =>
    handle.stop()

  @ready()
