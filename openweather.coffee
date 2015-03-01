module.exports = (env) ->

  Promise = env.require 'bluebird'
  convict = env.require "convict"
  assert = env.require 'cassert'
  
  weatherLib = require "openweathermap"

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

  class OpenWeatherDevice extends env.devices.Device
    attributes:
      status:
        description: "The actual status"
        type: "string"
      temperature:
        description: "The messured temperature"
        type: "number"
        unit: '°C'
      humidity:
        description: "The actual degree of Humidity"
        type: "number"
        unit: '%'
      pressure:
        description: "The expected pressure"
        type: "number"
        unit: 'mbar'
      windspeed:
        description: "The wind speed"
        type: "number"
        unit: 'km/h'
      rain:
        description: "Rain in mm per 3 hours"
        type: "number"
        unit: "mm"
      snow:
        description: "Snow in mm per 3 hours"
        type: "number"
        unit: "mm"

    status: "None"
    temperature: 0.0
    humidity: 0.0
    pressure: 0.0
    windspeed: 0.0
    rain: 0.0
    snow: 0.0

    constructor: (@config) ->
      @id = config.id
      @name = config.name
      @location = config.location
      @lang = config.lang
      @units = config.units
      @timeout = config.timeout
      super()

      setInterval(@requestForecast, @timeout)
      @requestForecast()

    requestForecast: () =>
      weatherLib.now {q: @location, lang: @lang, units: @units}, (result) =>
        if result.weather?
          @emit "status", result.weather[0].description
        if result.main?
          @emit "temperature", Number result.main.temp.toFixed(1)
          @emit "humidity", Number result.main.humidity.toFixed(1)
          @emit "pressure", Number result.main.pressure.toFixed(1)
        if result.wind?
          @emit "windspeed", Number result.wind.speed.toFixed(1)
        
        @emit "rain", if result.rain? then Number result.rain['3h'] else 0.0
        @emit "snow", if result.snow? then Number result.snow['3h'] else 0.0
   
    getStatus: -> Promise.resolve @status
    getTemperature: -> Promise.resolve @temperature
    getHumidity: -> Promise.resolve @humidity
    getPressure: -> Promise.resolve @pressure
    getWindspeed: -> Promise.resolve @windspeed
    getRain: -> Promise.resolve @rain
    getSnow: -> Promise.resolve @snow

  class OpenWeatherForecastDevice extends env.devices.Device
    attributes:
      forecast:
        description: "The expected forecast"
        type: "string"
      low:
        description: "The minimum temperature"
        type: "number"
        unit: '°C'
      high:
        description: "The maximum temperature"
        type: "number"
        unit: '°C'
      humidity:
        description: "The expected humidity"
        type: "number"
        unit: '%'
      pressure:
        description: "The expected pressure"
        type: "number"
        unit: 'mbar'
      windspeed:
        description: "The wind speed"
        type: "number"
        unit: 'km/h'
      rain:
        description: "Rain in mm per 3 hours"
        type: "number"
        unit: "mm"
      snow:
        description: "Snow in mm per 3 hours"
        type: "number"
        unit: "mm"

    forecast: "None"
    low: 0.0
    high: 0.0
    humidity: 0.0
    pressure: 0.0
    windspeed: 0.0
    rain: 0.0
    snow: 0.0

    constructor: (@config) ->
      @id = config.id
      @name = config.name
      @location = config.location
      @lang = config.lang
      @units = config.units
      @timeout = config.timeout
      @day = config.day
      super()

      setInterval(@requestForecast, @timeout)
      @requestForecast()

    requestForecast: () =>
      weatherLib.forecast {q: @location, lang: @lang, units: @units, cnt: @day}, (result) =>
        if result.list?
          today = new Date
          dateStart = new Date(today.getDate() + @day)
          dateEnd = new Date(today.getDate() + 1)
          dateStart.setHours 0
          dateStart.setMinutes 0
          dateStart.setSeconds 0
          dateEnd.setHours 23
          dateEnd.setMinutes 59
          dateEnd.setSeconds 59
          temp_min = +Infinity
          temp_max = -Infinity

          i = 0
          while i < result.list.length
            d = new Date(result.list[i].dt_txt)
            if dateStart <= d and d <= dateEnd
              if result.list[i].main.temp_min <= temp_min
                temp_min = result.list[i].main.temp_min
              if result.list[i].main.temp_max >= temp_max
                temp_max = result.list[i].main.temp_max
            i++

          @emit "low", Number temp_min.toFixed(1)
          @emit "high", Number temp_max.toFixed(1)

          if result.list[8*@day]?
            if result.list[8*@day].weather?
              @emit "forecast", result.list[8*@day].weather[0].description
            if result.list[8*@day].main?
              @emit "humidity", Number result.list[8*@day].main.humidity.toFixed(1)
              @emit "pressure", Number result.list[8*@day].main.pressure.toFixed(1)
            if result.list[8*@day].wind?
              @emit "windspeed", Number result.list[8*@day].wind.speed.toFixed(1)
            @emit "rain", if result.list[8*@day].rain? then Number result.list[8*@day].rain['3h'] else 0.0
            @emit "snow", if result.list[8*@day].snow? then Number result.list[8*@day].snow['3h'] else 0.0

    getForecast: -> Promise.resolve @forecast
    getLow: -> Promise.resolve @low
    getHigh: -> Promise.resolve @high
    getHumidity: -> Promise.resolve @humidity
    getPressure: -> Promise.resolve @pressure
    getWindspeed: -> Promise.resolve @windspeed
    getRain: -> Promise.resolve @rain
    getSnow: -> Promise.resolve @snow

  plugin = new OpenWeather
  return plugin
