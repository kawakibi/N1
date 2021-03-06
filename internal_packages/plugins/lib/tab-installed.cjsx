React = require 'react'
_ = require "underscore"
PackageSet = require './package-set'
PackagesStore = require './packages-store'
PluginsActions = require './plugins-actions'
{Spinner, EventedIFrame, Flexbox} = require 'nylas-component-kit'
classNames = require 'classnames'

class TabInstalled extends React.Component
  @displayName: 'TabInstalled'

  constructor: (@props) ->
    @state = @_getStateFromStores()

  render: =>
    searchEmpty = null
    if @state.search.length > 0
      searchEmpty = "No matching packages."

    if atom.inDevMode()
      devPackages = @state.packages.dev
      devEmpty = <span>
        You don't have any packages installed in ~/.nylas/dev/packages.
        These packages are only loaded when you run the app with debug flags
        enabled (via the Developer menu).<br/><br/>Learn more about building
        packages at <a href='https://nylas.com/N1/docs'>https://nylas.com/N1/docs</a>
      </span>
      devCTA = <div className="btn btn-large" onClick={@_onCreatePackage}>Create New Package...</div>
    else
      devPackages = []
      devEmpty = <span>Run with debug flags enabled to load ~/.nylas/dev/packages.</span>
      devCTA = <div className="btn btn-large" onClick={@_onEnableDevMode}>Enable Debug Flags</div>

    <div className="installed">
      <div className="inner">
        <input
          type="search"
          value={@state.search}
          onChange={@_onSearchChange }
          placeholder="Search Installed Packages"/>
        <PackageSet
          packages={@state.packages.user}
          title="Installed"
          emptyText={searchEmpty ? <span>You don't have any packages installed in ~/.nylas/packages.</span>} />
        <PackageSet
          title="Development"
          packages={devPackages}
          emptyText={searchEmpty ? devEmpty} />
        <div className="new-package">
          {devCTA}
        </div>
        <PackageSet
          title="Core"
          packages={@state.packages.core} />
      </div>
    </div>

  _onEnableDevMode: =>
    require('ipc').send('command', 'application:toggle-dev')

  componentDidMount: =>
    @_unsubscribers = []
    @_unsubscribers.push PackagesStore.listen(@_onChange)

    PluginsActions.refreshInstalledPackages()

  componentWillUnmount: =>
    unsubscribe() for unsubscribe in @_unsubscribers

  _getStateFromStores: =>
    packages: PackagesStore.installed()
    search: PackagesStore.installedSearchValue()

  _onChange: =>
    @setState(@_getStateFromStores())

  _onCreatePackage: =>
    PluginsActions.createPackage()

  _onSearchChange: (event) =>
    PluginsActions.setInstalledSearchValue(event.target.value)

module.exports = TabInstalled
