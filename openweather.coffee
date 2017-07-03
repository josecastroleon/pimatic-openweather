module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'

  weatherLib = require "openweathermap"
  Promise.promisifyAll(weatherLib)
  PromiseRetryer = require('promise-retryer')(Promise)

  class OpenWeather extends env.plugins.Plugin
    init: (app, @framework, @config) =>
      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("OpenWeatherDevice", {
        configDef: deviceConfigDef.OpenWeatherDevice,
        createCallback: (config, lastState) => new OpenWeatherDevice(config, lastState, @config.apiKey)
      })
      @framework.deviceManager.registerDeviceClass("OpenWeatherForecastDevice", {
        configDef: deviceConfigDef.OpenWeatherForecastDevice,
        createCallback: (config) => new OpenWeatherForecastDevice(config, @config.apiKey)
      })

      # some legacy handling:
      if @framework.config?
        for device in @framework.config.devices
          if device.class in ["OpenWeatherDevice", "OpenWeatherForecastDevice"]
            if device.apiKey?.length > 0
              @config.apiKey = device.apiKey
              delete device.apiKey


  handleError = (result) ->
    code = parseInt(result.cod, 10)
    if code isnt 200
      if result.message?.length > 0
        throw new Error("#{result.message} (#{code})")
      else
        if code is 404
          throw new Error("Location not found")
        else
          throw new Error("Error code: #{code}")


  class OpenWeatherDevice extends env.devices.Device
    attributes:
      status:
        description: "The actual status"
        type: "string"
      status-cagetory:
        description: "Category of the actual status"
        type: "string"
      status-id:
        description: "ID of the actual status"
        type: "number"
        acronym: "#"
      temperature:
        description: "The measured temperature"
        type: "number"
        unit: '°C'
        acronym: 'T'
      humidity:
        description: "The actual degree of Humidity"
        type: "number"
        unit: '%'
        acronym: 'RH'
      pressure:
        description: "The expected pressure"
        type: "number"
        unit: 'mbar'
        acronym: 'P'
      windspeed:
        description: "The wind speed"
        type: "number"
        unit: 'm/s'
        acronym: 'WIND'
      rain:
        description: "Rain in mm per 3 hours"
        type: "number"
        unit: "mm"
        acronym: 'RAIN'
      snow:
        description: "Snow in mm per 3 hours"
        type: "number"
        unit: "mm"
        acronym: 'SNOW'
      clouds:
        description: "Cloudyness"
        type: "number"
        unit: '%'
        acronym: 'CLOUDS'

    status: "None"
    status-category: "None"
    status-id: null
    temperature: null
    humidity: null
    pressure: null
    windspeed: null
    rain: null
    snow: null
    clouds: null

    constructor: (@config, lastState, apiKey) ->
      @id = @config.id
      @name = @config.name
      @timeout = @config.timeout
      @timeoutOnError = @config.timeoutOnError
      @serviceProperties = lang: @config.lang, units: @config.units, agent: false
      if @config.cityId?
        @serviceProperties.id = @config.cityId
      else
        @serviceProperties.q = @config.location
      
      unless apiKey?
        env.logger.warn "Missing API key. Service request may be blocked"
      else
        @serviceProperties.appid = apiKey

      # set attribute value with last state from DB
      if lastState?
        for own key of @attributes
          @[key] = lastState[key].value if lastState[key]?

      @attributes = _.cloneDeep(@attributes)
      if @config.units is "imperial"
        @attributes["temperature"].unit = '°F'
        @attributes["windspeed"].unit = 'mph'
      else if @config.units is "standard"
        @attributes["temperature"].unit = 'K'
      super()
      @requestWeatherData()

    destroy: () ->
      @requestPromise.cancel() if @requestPromise?
      clearTimeout @requestWeatherDataTimeout if @requestWeatherDataTimeout?
      super

    checkIfBlacklisted: (result) ->
      match =
        base: result.base
        id: result.weather?[0].id
        temperature: @_toFixed(result.main.temp, 1)

      env.logger.debug "Weather data received: #{JSON.stringify match}"
      isBlacklisted = false
      if @config.blacklist.length isnt 0
        isBlacklisted = @config.blacklist.some (entry) ->
          Object.keys(entry).every (key) ->
            entry[key] is match[key]

      if not isBlacklisted and @lastMatch? and Math.abs(@lastMatch.temperature - match.temperature) > 3.5
        env.logger.info
        "Potential outlier detected, previous: #{JSON.stringify @lastMatch}, current: #{JSON.stringify match}"

      @lastMatch = match
      return isBlacklisted


    requestWeatherData: () =>
      @requestWeatherDataTimeout = null
      @requestPromise = PromiseRetryer.run(
        delay: 1000,
        maxRetries: 5,
        promise: => weatherLib.nowAsync(@serviceProperties)
      ).then( (result) =>
        handleError(result)
        if @checkIfBlacklisted result
          env.logger.debug "Result is blacklisted. Skipping ..."
        else
          if result.weather?
            @_setAttribute "status", result.weather[0].description, true
            @_setAttribute "status-category", result.weather[0].main, true
            @_setAttribute "status-id", parseInt(result.weather[0].id)
          if result.main?
            @_setAttribute "temperature", @_toFixed(result.main.temp, 1)
            @_setAttribute "humidity", @_toFixed(result.main.humidity, 1)
            @_setAttribute "pressure", @_toFixed(result.main.pressure, 1)
          if result.wind?
            @_setAttribute "windspeed", @_toFixed(result.wind.speed, 1)
          @_setAttribute "rain", (
            if result.rain? and Object.keys(result.rain).length isnt 0
            then @_toFixed(result.rain[Object.keys(result.rain)[0]], 1)
            else 0.0
          )
          @_setAttribute "snow", (
            if result.snow? and Object.keys(result.snow).length isnt 0
            then @_toFixed(result.snow[Object.keys(result.snow)[0]], 1)
            else 0.0
          )
          if result.clouds?
            @_setAttribute "clouds", @_toFixed(result.clouds.all, 0)
        @_currentRequest = Promise.resolve()
        @requestWeatherDataTimeout = setTimeout(@requestWeatherData, @timeout)
      ).catch( (err) =>
        unless @lastError?.message is err.message
          env.logger.error(err.message)
          env.logger.debug(err.stack)
        @lastError = err
        @requestWeatherDataTimeout = setTimeout(@requestWeatherData, @timeoutOnError)
      )
      @_currentRequest = @requestPromise unless @_currentRequest?
      return @requestPromise

    _toFixed: (value, nDecimalDigits) ->
      if _.isNumber(value)
        return Number value.toFixed(nDecimalDigits)
      else
        return Number value

    _setAttribute: (attributeName, value, discrete = false) ->
      if not discrete or @[attributeName] isnt value
        @[attributeName] = value
        @emit attributeName, value

    getStatus: -> @_currentRequest.then(=> @status )
    getStatusCategory: -> @_currentRequest.then(=> @status-category )
    getStatusId: -> @_currentRequest.then(=> @status-id )
    getTemperature: -> @_currentRequest.then(=> @temperature )
    getHumidity: -> @_currentRequest.then(=> @humidity )
    getPressure: -> @_currentRequest.then(=> @pressure )
    getWindspeed: -> @_currentRequest.then(=> @windspeed )
    getRain: -> @_currentRequest.then(=> @rain )
    getSnow: -> @_currentRequest.then(=> @snow )
    getClouds: -> @_currentRequest.then(=> @clouds )


  class OpenWeatherForecastDevice extends env.devices.Device
    attributes:
      forecast:
        description: "The expected forecast"
        type: "string"
      low:
        description: "The minimum temperature"
        type: "number"
        unit: '°C'
        acronym: 'LOW'
      high:
        description: "The maximum temperature"
        type: "number"
        unit: '°C'
        acronym: 'HIGH'
      humidity:
        description: "The expected humidity"
        type: "number"
        unit: '%'
        acronym: 'RH'
      pressure:
        description: "The expected pressure"
        type: "number"
        unit: 'mbar'
        acronym: 'P'
      windspeed:
        description: "The wind speed"
        type: "number"
        unit: 'm/s'
        acronym: 'WIND'
      rain:
        description: "Rain in mm per 3 hours"
        type: "number"
        unit: "mm"
        acronym: 'RAIN'
      snow:
        description: "Snow in mm per 3 hours"
        type: "number"
        unit: "mm"
        acronym: 'SNOW'
      clouds:
        description: "Clouds in percentage"
        type: "number"
        unit: "%"
        acronym: "CLOUDS"

    forecast: "None"
    low: null
    high: null
    humidity: null
    pressure: null
    windspeed: null
    rain: null
    snow: null
    clouds: null

    constructor: (@config, apiKey) ->
      @id = @config.id
      @name = @config.name
      @timeout = @config.timeout
      @timeoutOnError = @config.timeoutOnError
      @day = @config.day
      @arrayday = @day - 1
      @serviceProperties = lang: @config.lang, units: @config.units, cnt: @day, agent: false

      if @config.cityId?
        @serviceProperties.id = @config.cityId
      else
        @serviceProperties.q = @config.location
        
      unless apiKey?
        env.logger.warn "Missing API key. Service request may be blocked"
      else
        @serviceProperties.appid = apiKey

      if @config.units is "imperial"
        @attributes["low"].unit = '°F'
        @attributes["high"].unit = '°F'
        @attributes["windspeed"].unit = 'mph'
      else if @config.units is "standard"
        @attributes["low"].unit = 'K'
        @attributes["high"].unit = 'K'
      super()
      @requestForecast()

    destroy: () ->
      @requestPromise.cancel() if @requestPromise?
      clearTimeout @requestForecastTimeout if @requestForecastTimeout?
      super

    requestForecast: () =>
      @requestForecastTimeout = null
      @requestPromise = PromiseRetryer.run(
        delay: 1000,
        maxRetries: 5,
        promise: =>
          weatherLib.dailyAsync(@serviceProperties)
      ).then( (result) =>
        handleError(result)
        env.logger.debug "Forecast result contains data for #{result.cnt} day(s)"

        if result.list[@arrayday]?
          temp_min = +Infinity
          temp_max = -Infinity
          if result.list[@arrayday].temp.min <= temp_min
            temp_min = result.list[@arrayday].temp.min
          if result.list[@arrayday].temp.max >= temp_max
            temp_max = result.list[@arrayday].temp.max

          @_setAttribute "low", @_toFixed(temp_min, 1)
          @_setAttribute "high", @_toFixed(temp_max, 1)

          if result.list[@arrayday].weather?
            @_setAttribute "forecast", result.list[@arrayday].weather[0].description, true

          @_setAttribute "humidity", @_toFixed(result.list[@arrayday].humidity, 1)
          @_setAttribute "pressure", @_toFixed(result.list[@arrayday].pressure, 1)
          @_setAttribute "windspeed", @_toFixed(result.list[@arrayday].speed, 1)

          @_setAttribute "rain", (
            if result.list[@arrayday].rain? then @_toFixed(result.list[@arrayday].rain, 1) else 0.0
          )
          @_setAttribute "snow", (
            if result.list[@arrayday].snow? then @_toFixed(result.list[@arrayday].snow, 1) else 0.0
          )
          @_setAttribute "clouds", (
            if result.list[@arrayday].clouds? then @_toFixed(result.list[@arrayday].clouds, 0) else 0
          )
        else
          env.logger.debug "No data found for #{@day}-day forecast"

        @_currentRequest = Promise.resolve()
        @requestForecastTimeout = setTimeout(@requestForecast, @timeout)
      ).catch( (err) =>
        unless @lastError?.message is err.message
          env.logger.error(err.message)
          env.logger.debug(err.stack)
        @lastError = err
        @requestForecastTimeout = setTimeout(@requestForecast, @timeoutOnError)
      )
      @_currentRequest = @requestPromise unless @_currentRequest?
      return @requestPromise

    _toFixed: (value, nDecimalDigits) ->
      if _.isNumber(value)
        return Number value.toFixed(nDecimalDigits)
      else
        return Number value

    _setAttribute: (attributeName, value) ->
      unless @[attributeName] is value
        @[attributeName] = value
        @emit attributeName, value

    getForecast: -> @_currentRequest.then(=> @forecast )
    getLow: -> @_currentRequest.then(=> @low )
    getHigh: -> @_currentRequest.then(=> @high )
    getHumidity: -> @_currentRequest.then(=> @humidity )
    getPressure: -> @_currentRequest.then(=> @pressure )
    getWindspeed: -> @_currentRequest.then(=> @windspeed )
    getRain: -> @_currentRequest.then(=> @rain )
    getSnow: -> @_currentRequest.then(=> @snow )
    getClouds: -> @_currentRequest.then(=> @clouds )

  plugin = new OpenWeather
  return plugin
