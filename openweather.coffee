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
        createCallback: (config) => new OpenWeatherDevice(config)
      })
      @framework.deviceManager.registerDeviceClass("OpenWeatherForecastDevice", {
        configDef: deviceConfigDef.OpenWeatherForecastDevice,
        createCallback: (config) => new OpenWeatherForecastDevice(config)
      })

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

    status: "None"
    temperature: null
    humidity: null
    pressure: null
    windspeed: null
    rain: null
    snow: null

    constructor: (@config) ->
      @id = config.id
      @name = config.name
      @location = config.location
      @lang = config.lang
      @units = config.units
      @timeout = config.timeout
      @attributes = _.cloneDeep(@attributes)
      if @units is "imperial"
        @attributes["temperature"].unit = '°F'
        @attributes["windspeed"].unit = 'mph'
      else if @units is "standard"
        @attributes["temperature"].unit = 'K'
      super()
      @requestForecast()

    requestForecast: () =>
      request = PromiseRetryer.run(
        delay: 1000,
        maxRetries: 5,
        promise: => weatherLib.nowAsync( q: @location, lang: @lang, units: @units )
      ).then( (result) =>
        handleError(result)
        if result.weather?
          @_setAttribute "status", result.weather[0].description
        if result.main?
          @_setAttribute "temperature", @_toFixed(result.main.temp, 1)
          @_setAttribute "humidity", @_toFixed(result.main.humidity, 1)
          @_setAttribute "pressure", @_toFixed(result.main.pressure, 1)
        if result.wind?
          @_setAttribute "windspeed", @_toFixed(result.wind.speed, 1)
        @_setAttribute "rain", (
          if result.rain? then @_toFixed(result.rain[Object.keys(result.rain)[0]], 1) else 0.0
        )
        @_setAttribute "snow", (
          if result.snow? then @_toFixed(result.snow[Object.keys(result.rain)[0]], 1) else 0.0
        )
        @_currentRequest = Promise.resolve()
        setTimeout(@requestForecast, @timeout)
      ).catch( (err) =>
        env.logger.error(err.message)
        env.logger.debug(err.stack)
        setTimeout(@requestForecast, @timeout)
      )
      request.done()
      @_currentRequest = request unless @_currentRequest?
      return request

    _toFixed: (value, nDecimalDigits) ->
      if _.isNumber(value)
        return Number value.toFixed(nDecimalDigits)
      else
        return Number value

    _setAttribute: (attributeName, value) ->
      unless @[attributeName] is value
        @[attributeName] = value
        @emit attributeName, value

    getStatus: -> @_currentRequest.then(=> @status )
    getTemperature: -> @_currentRequest.then(=> @temperature )
    getHumidity: -> @_currentRequest.then(=> @humidity )
    getPressure: -> @_currentRequest.then(=> @pressure )
    getWindspeed: -> @_currentRequest.then(=> @windspeed )
    getRain: -> @_currentRequest.then(=> @rain )
    getSnow: -> @_currentRequest.then(=> @snow )


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

    forecast: "None"
    low: null
    high: null
    humidity: null
    pressure: null
    windspeed: null
    rain: null
    snow: null

    constructor: (@config) ->
      @id = config.id
      @name = config.name
      @location = config.location
      @lang = config.lang
      @units = config.units
      @timeout = config.timeout
      @day = config.day
      @arrayday = @day-1

      if @units is "imperial"
        @attributes["low"].unit = '°F'
        @attributes["high"].unit = '°F'
        @attributes["windspeed"].unit = 'mph'
      else if @units is "standard"
        @attributes["low"].unit = 'K'
        @attributes["high"].unit = 'K'
      super()
      @requestForecast()

    requestForecast: () =>

      request = PromiseRetryer.run(
        delay: 1000,
        maxRetries: 5,
        promise: =>
          weatherLib.dailyAsync( q: @location, lang: @lang, units: @units, cnt: @day )
      ).then( (result) =>
        handleError(result)

        if result.list[@arrayday]?
          temp_min = +Infinity
          temp_max = -Infinity
          if result.list[@arrayday].temp.min <= temp_min
            temp_min = result.list[@arrayday].temp.min
          if result.list[@arrayday].temp.max >= temp_max?
            temp_max = result.list[@arrayday].temp.max

          @_setAttribute "low", @_toFixed(temp_min, 1)
          @_setAttribute "high", @_toFixed(temp_max, 1)

          if result.list[@arrayday].weather?
            @_setAttribute "forecast", result.list[@arrayday].weather[0].description

          @_setAttribute "humidity", @_toFixed(result.list[@arrayday].humidity, 1)
          @_setAttribute "pressure", @_toFixed(result.list[@arrayday].pressure, 1)
          @_setAttribute "windspeed", @_toFixed(result.list[@arrayday].speed, 1)

          @_setAttribute "rain", if result.list[@arrayday].rain? then @_toFixed(result.list[@arrayday].rain, 1) else 0.0
          @_setAttribute "snow", if result.list[@arrayday].snow? then @_toFixed(result.list[@arrayday].snow, 1) else 0.0


        else
          env.logger.debug "No data found for #{@day}-day forecast"

        @_currentRequest = Promise.resolve()
        setTimeout(@requestForecast, @timeout)
      ).catch( (err) =>
        env.logger.error(err.message)
        env.logger.debug(err.stack)
        setTimeout(@requestForecast, @timeout)
      )
      request.done()
      @_currentRequest = request unless @_currentRequest?
      return request

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

  plugin = new OpenWeather
  return plugin
