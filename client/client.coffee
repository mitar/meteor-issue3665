TestCollection.find({}).observeChanges
  added: (id, fields) ->
    console.log id, fields
