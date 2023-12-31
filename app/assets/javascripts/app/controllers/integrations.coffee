class Integrations extends App.ControllerSubContent
  requiredPermission: 'admin.integration'
  header: __('Integrations')
  constructor: ->
    super

    @integrationItems = App.Config.get('NavBarIntegrations')
    @subscribeId = App.Setting.subscribe(@render, initFetch: true, clear: false)

  show: (params) =>
    return if !params.target && !params.integration if @initRender

    @target = params.target
    @integration = params.integration
    if !@initRender
      @requestedIntegration = true
      return

    if !@integration
      if !params.noRender
        @render()
      return

    for key, value of @integrationItems
      if value.target is "#system/#{params.target}/#{params.integration}"
        config = value
        break

    @configController.releaseController() if @configController
    @configController = new config.controller(
      el:           @el.find('.js-integration')
      success_code: params.success_code
      error_code:   params.error_code
    )

  render: =>
    return if @initRender && @integration

    @initRender = true
    integrations = []
    for key, value of @integrationItems
      if !value.permission
        value.key = key
        integrations.push value
      else
        match = false
        for permissionName in value.permission
          if !match && @permissionCheck(permissionName)
            match = true
            value.key = key
            integrations.push value
    integrations = _.sortBy(integrations, (item) -> return item.name)
    @html App.view('integration/index')(
      head:         __('Integrations')
      integrations: integrations
    )

    return if !@requestedIntegration
    @show(
      target:       @target
      integration:  @integration
      success_code: @success_code
      error_code:   @error_code
      noRender:     true
    )
    @requestedIntegration = undefined

  release: =>
    if @subscribeId
      App.Setting.unsubscribe(@subscribeId)

App.Config.set('Integration', { prio: 1000, name: __('Integrations'), parent: '#system', target: '#system/integration', controller: Integrations, permission: ['admin.integration'] }, 'NavBarAdmin')
