{DatabaseStore, DraftStore, Actions, Message, React} = require 'nylas-exports'
NylasStore = require 'nylas-store'
shell = require 'shell'
path = require 'path'
fs = require 'fs'

class TemplateStore extends NylasStore
  constructor: ->
    @_setStoreDefaults()
    @_registerListeners()

    @_templatesDir = path.join(atom.getConfigDirPath(), 'templates')
    @_welcomeName = 'Welcome to Templates.html'
    @_welcomePath = path.join(__dirname, '..', 'assets', @_welcomeName)

    # I know this is a bit of pain but don't do anything that
    # could possibly slow down app launch
    fs.exists @_templatesDir, (exists) =>
      if exists
        @_populate()
        fs.watch @_templatesDir, => @_populate()
      else
        fs.mkdir @_templatesDir, =>
          fs.readFile @_welcomePath, (err, welcome) =>
            fs.writeFile path.join(@_templatesDir, @_welcomeName), welcome, (err) =>
              fs.watch @_templatesDir, => @_populate()


  ########### PUBLIC #####################################################

  items: =>
    @_items

  templatesDirectory: =>
    @_templatesDir


  ########### PRIVATE ####################################################

  _setStoreDefaults: =>
    @_items = []

  _registerListeners: =>
    @listenTo Actions.insertTemplateId, @_onInsertTemplateId
    @listenTo Actions.createTemplate, @_onCreateTemplate
    @listenTo Actions.showTemplates, @_onShowTemplates

  _populate: =>
    fs.readdir @_templatesDir, (err, filenames) =>
      @_items = []
      for filename in filenames
        continue if filename[0] is '.'
        displayname = path.basename(filename, path.extname(filename))
        @_items.push
          id: filename,
          name: displayname,
          path: path.join(@_templatesDir, filename)
      @trigger(@)

  _onCreateTemplate: ({draftClientId, name, contents} = {}) =>
    if draftClientId
      DraftStore.sessionForClientId(draftClientId).then (session) =>
        draft = session.draft()
        name ?= draft.subject
        contents ?= draft.body
        if not name or name.length is 0
          return @_displayError("Give your draft a subject to name your template.")
        if not contents or contents.length is 0
          return @_displayError("To create a template you need to fill the body of the current draft.")
        @_writeTemplate(name, contents)

    else
      if not name or name.length is 0
        return @_displayError("You must provide a name for your template.")
      if not contents or contents.length is 0
        return @_displayError("You must provide contents for your template.")
      @_writeTemplate(name, contents)

  _onShowTemplates: =>
    shell.showItemInFolder(@_items[0]?.path || @_templatesDir)

  _displayError: (message) =>
    dialog = require('remote').require('dialog')
    dialog.showErrorBox('Template Creation Error', message)

  _writeTemplate: (name, contents) =>
    filename = "#{name}.html"
    templatePath = path.join(@_templatesDir, filename)
    fs.writeFile templatePath, contents, (err) =>
      @_displayError(err) if err
      shell.showItemInFolder(templatePath)
      @_items.push
        id: filename,
        name: name,
        path: templatePath
      @trigger(@)

  _onInsertTemplateId: ({templateId, draftClientId} = {}) =>
    template = null
    for item in @_items
      template = item if item.id is templateId
    return unless template

    fs.readFile template.path, (err, data) ->
      body = data.toString()
      DraftStore.sessionForClientId(draftClientId).then (session) ->
        session.changes.add(body: body)

module.exports = new TemplateStore()
