function init()
  m.TAP_SDK_VERSION = "1.0.1"
  m.top.id = "tap"

  m.messagePort = _createPort()

  m.top.observeField("startTaplytics", m.messagePort)
  m.top.observeField("setUserAttributes", m.messagePort)
  m.top.observeField("logEvent", m.messagePort)
  m.top.observeField("resetAppUser", m.messagePort)

  m.taplytics = Taplytics()
  m.top.functionName = "runLoop"
  m.top.control = "RUN"
end function

function runLoop()

  appInfo = _createAppInfo()

  m.MAX_BEACON_SIZE = 300 'controls size of a single beacon (in events)
  m.MAX_QUEUE_LENGTH = 3600 '1 minute to clean a full queue
  m.BASE_TIME_BETWEEN_BEACONS = 5000
  m.HEARTBEAT_INTERVAL = 10000
  m.POSITION_TIMER_INTERVAL = 250 '250
  m.SEEK_THRESHOLD = 1250 'ms jump in position before a seek is considered'
  m.HTTP_RETRIES = m.top.HTTP_RETRIES 'number of times to reattempt http call'
  m.HTTP_TIMEOUT = 10000 'time before an http call is cancelled (ms)'

  m.taplytics.TAP_SDK_VERSION = m.TAP_SDK_VERSION
  m.taplytics.KEY = m.top.key
  m.taplytics.httpPort = m.messagePort
  m.taplytics.connection = _createConnection(m.taplytics.httpPort)


  systemConfig = {
                  MAX_BEACON_SIZE: m.MAX_BEACON_SIZE,
                  MAX_QUEUE_LENGTH: m.MAX_QUEUE_LENGTH,
                  HTTP_RETRIES: m.HTTP_RETRIES,
                  HTTP_TIMEOUT: m.HTTP_TIMEOUT,
                  BASE_TIME_BETWEEN_BEACONS: m.BASE_TIME_BETWEEN_BEACONS,
                  HEARTBEAT_INTERVAL: m.HEARTBEAT_INTERVAL,
                  POSITION_TIMER_INTERVAL: m.POSITION_TIMER_INTERVAL,
                  SEEK_THRESHOLD: m.SEEK_THRESHOLD,
                 }
  m.taplytics.init(appInfo, systemConfig, m.top.key, m.top.config, m.heartbeatTimer, m.pollTimer)

  running = true
  while(running)
    msg = wait(0, m.messagePort)
    if m.top.exit = true
      running = false
    end if
    if msg <> Invalid
      msgType = type(msg)
      if msgType = "roSGNodeEvent"
        field = msg.getField()
        data = msg.getData()

        if field = "startTaplytics"
          m.taplytics.startTaplytics(data)
        else if field = "setUserAttributes"
          m.taplytics.setUserAttributes(data)
        else if field = "logEvent"
          m.taplytics.logEvent(data)
        else if field = "resetAppUser"
          m.taplytics.resetAppUser()
        else if field = "response"
          if data.name = "clientConfig"
            m.taplytics._onGetClientConfig(data)
          else if data.name = "clientAppUser"
            m.taplytics._onPostClientAppUser(data)
          else if data.name = "clientEvents"
            m.taplytics._onPostClientEvents(data)
          else if data.name = "resetAppUser"
            m.taplytics._onPostResetAppUser(data)
          end if
        end if
      end if
    end if
  end while

  m.top.UnobserveField("startTaplytics")
  m.top.UnobserveField("setUserAttributes")
  m.top.UnobserveField("logEvent")
  m.top.UnobserveField("resetAppUser")

  return true
end function

function _createConnection(port as Object) as Object
  connection = CreateObject("roUrlTransfer")
  connection.SetPort(port)
  connection.SetCertificatesFile("common:/certs/ca-bundle.crt")
  connection.AddHeader("Content-Type", "application/json")
  connection.AddHeader("Accept", "*/*")
  connection.AddHeader("Expect", "")
  connection.AddHeader("Connection", "keep-alive")
  connection.AddHeader("Accept-Encoding", "gzip, deflate, br")

  connection.RetainBodyOnError(true)
  connection.EnableEncodings(true)
  return connection
end function

function _createDeviceInfo() as Object
  return CreateObject("roDeviceInfo")
end function

function _createPort() as Object
  return CreateObject("roMessagePort")
end function

function _createByteArray() as Object
  return CreateObject("roByteArray")
end function

function _createAppInfo() as Object
  return CreateObject("roAppInfo")
end function

function _createRegistry() as Object
  return CreateObject("roRegistrySection", "tap")
end function

function Taplytics() as Object
  prototype = {}

  prototype.TAP_SDK_VERSION = "1.0.1"
  prototype.PLAYER_SOFTWARE_NAME = "RokuSG"
  prototype.TAP_API_VERSION = "2.0"
  prototype.PLAYER_IS_FULLSCREEN = "true"
  prototype.KEY = ""

  prototype._top = m.top

  prototype.httpPort = invalid
  prototype.connection = invalid
  prototype._clientConfig = invalid
  prototype._variables = {}
  prototype._clientConfigReady = false

  prototype.init = function(appInfo as Object, systemConfig as Object, key as String, customerConfig as Object, hbt as Object, pp as Object)
    m.httpRetries = 5
    m.httpTimeout = 1500
    m.heartbeatTimer = hbt
    m.pollTimer = pp

    m.DEFAULT_URL = "https://api.taplytics.com/api"
    m.DEFAULT_PING_URL = "https://ping.taplytics.com/api"

    m.MAX_BEACON_SIZE = systemConfig.MAX_BEACON_SIZE
    m.MAX_QUEUE_LENGTH = systemConfig.MAX_QUEUE_LENGTH
    m.HTTP_RETRIES = systemConfig.HTTP_RETRIES
    m.HTTP_TIMEOUT = systemConfig.HTTP_TIMEOUT
    m.BASE_TIME_BETWEEN_BEACONS = systemConfig.BASE_TIME_BETWEEN_BEACONS
    m.HEARTBEAT_INTERVAL = systemConfig.HEARTBEAT_INTERVAL
    m.POSITION_TIMER_INTERVAL = systemConfig.POSITION_TIMER_INTERVAL
    m.SEEK_THRESHOLD = systemConfig.SEEK_THRESHOLD

    m._configProperties = customerConfig

    m._eventQueue = []
    m._seekThreshold = m.SEEK_THRESHOLD / 1000

    m._sessionProperties = m._getSessionProperites()

  end function





  ' ' //////////////////////////////////////////////////////////////
  ' ' PUBLIC APIs
  ' ' //////////////////////////////////////////////////////////////
  '  1. startTaplytics
  '  2. getRunningExperimentsAndVariations
  '  3. getVariationForExperiment
  '  4. getValueForVariable
  '  5. logEvent
  '  6. setUserAttributes
  '  7. resetAppUser
  '  8. startNewSession
  prototype.startTaplytics = function(data as Object)
    if m._top.enablePrint then print "ENTER startTaplytics>>>"
    m._getClientConfig(data)
  end function

  prototype.setUserAttributes = function(data as Object)
    if m._top.enablePrint then print "ENTER setUserAttributes>>>"
    m._postClientAppUser(data)
  end function

  prototype.logEvent = function(data as Object)
    if m._top.enablePrint then print "ENTER logEvent>>>"
    m._postClientEvents(data)
  end function

  prototype.resetAppUser = function()
    if m._top.enablePrint then print "ENTER resetAppUser"
    m._postResetAppUser()
  end function





  ' ' //////////////////////////////////////////////////////////////
  ' ' NETWORK APIs
  ' ' //////////////////////////////////////////////////////////////
  '  1. Client Config (GET) -     _getClientConfig
  '  2. Client Events (POST) -    _clientEvents
  '  3. Client App User (POST) -  _clientAppUser
  '  4. Reset AppUser (POST) -    _resetAppUser

  prototype._getClientConfig = function(queryParameters as Object)

    optionalParamaters = {}
    requiredParamaters = {}

    'os - device operating system
    requiredParamaters.os = m._sessionProperties.viewer_os_family

    'osv - device operating system version
    requiredParamaters.osv = m._sessionProperties.viewer_os_version

    'dn - device name (optional)
    if queryParameters.DoesExist("dn")
      if queryParameters.dn <> invalid
        optionalParamaters.dn = queryParameters.dn
      end if
    end if

    'rm - release mode of the build / 1 if dev - else 3
    'lv - live update mode / 1/0
    'dev - live update manually set (from starting options) / 1/0
    if m._sessionProperties.is_dev
      requiredParamaters.rm = 1
      requiredParamaters.lv = 0
      requiredParamaters.dev = 1
    else
      requiredParamaters.rm = 3
      requiredParamaters.lv = 1
      requiredParamaters.dev = 0
    end if

    'ma - manufacturer (optional)
    if queryParameters.DoesExist("ma") and queryParameters.ma <> ""
       optionalParamaters.ma = queryParameters.ma
    end if

    'br - brand (optional)
    if queryParameters.DoesExist("br") and queryParameters.br <> ""
      optionalParamaters.br = queryParameters.br
    end if

    'd - device type
    requiredParamaters.d = m._sessionProperties.player_model_number

    'sdk - version of the sdk
    requiredParamaters.sdk = m._sessionProperties.player_tap_plugin_version

    'av - version of the app
    requiredParamaters.av = m._sessionProperties.application_version

    'ad - device adID identifier
    requiredParamaters.ad = m._sessionProperties.player_unique_id

    'an - name of the app (optional but recommended)
    requiredParamaters.an = m._sessionProperties.player_tap_plugin_name

    'ab - build version (optional)
    if queryParameters.DoesExist("ab") and queryParameters.ab <> ""
      optionalParamaters.ab = queryParameters.ab
    end if

    't - Taplytics API Key
    requiredParamaters.t = m.KEY

    'ai - identifier of the app (optional)
    'alg - language of the app (optional but recommended) ● en
    optionalParamaters.alg = m._sessionProperties.player_language_code

    'alg3 - ISO3 language of the app (optional but recommended) ● eng
    'plg - preferred language (optional but recommended) ● en
    'con - country (optional but recommended) ● ca
    optionalParamaters.con = m._sessionProperties.player_country_code

    'con3 - country in ISO3 format (optional but recommended) ● USA
    'tzn - time zone name (optional but recommended) ● Pacific Daylight Time
    optionalParamaters.tzn = m._sessionProperties.player_time_zone

    'tz - time zone abbreviation (optional but recommended) ● EDT
    'tzs - time zone seconds from GMT (optional but recommended) ● 0  integer number
    'sw - screen width (optional) ● 1920
    optionalParamaters.sw = m._sessionProperties.player_width

    'sh - screen height (optional) ● 1080
    optionalParamaters.sw = m._sessionProperties.player_height

    'n - network type (optional) ● WiFi  or  WWAN
    optionalParamaters.n = m._sessionProperties.player_connection_type

    'exp - list of experiment_ids (optional) ● JSON array of experiment_ids
    'var - list of variation_ids (optional)
    'uid - AppUser user_id (optional)
    'aua - AppUser attribute changes to set. (optional)
    'uev - User test experiment/variations set in startTaplytics options (optional)

    timeout = m.HTTP_TIMEOUT
    if queryParameters.DoesExist("timeout")
      timeout = queryParameters.timeout
    end if

    api = "/v1/clientConfig/"
    method = "GET"
    name = "clientConfig"
    context = createObject("RoSGNode","Node")
    context.addFields({
        response: {}
    })
    context.observeField("response", m.httpPort)
    requiredParamaters.Append(optionalParamaters)
    m._makeRequest(m.DEFAULT_URL, api, method, name, context, requiredParamaters, {}, timeout)

  end function

  prototype._postClientAppUser = function(queryParameters as Object)

    optionalParamaters = {}
    requiredParamaters = {}

    requiredParamaters.t = m.KEY
    requiredParamaters.pid = m._variables._project
    requiredParamaters.sid = m._variables.sid
    requiredParamaters.auid = m._variables.au_id
    requiredParamaters.k = "a4cbf0842807b43a0000"

    au = {}
    if queryParameters.DoesExist("user_id") and queryParameters.user_id <> ""
      au.user_id = queryParameters.user_id
    end if

    if queryParameters.DoesExist("name") and queryParameters.name <> ""
      au.name = queryParameters.name
    end if

    if queryParameters.DoesExist("firstName") and queryParameters.firstName <> ""
      au.firstName = queryParameters.firstName
    end if

    if queryParameters.DoesExist("lastName") and queryParameters.lastName <> ""
      au.lastName = queryParameters.lastName
    end if

    if queryParameters.DoesExist("email") and queryParameters.email <> ""
      au.email = queryParameters.email
    end if

    if queryParameters.DoesExist("gender") and queryParameters.gender <> ""
      au.gender = queryParameters.gender
    end if

    if queryParameters.DoesExist("age")
      au.age = queryParameters.age
    end if

    if queryParameters.DoesExist("avatarUrl") and queryParameters.avatarUrl <> ""
      au.avatarUrl = queryParameters.avatarUrl
    end if
    requiredParamaters.au = au

    api = "/v1/clientAppUser/"
    method = "POST"
    name = "clientAppUser"
    context = createObject("RoSGNode","Node")
    context.addFields({
        response: {}
    })
    context.observeField("response", m.httpPort)
    requiredParamaters.Append(optionalParamaters)
    m._makeRequest(m.DEFAULT_URL, api, method, name, context, {}, requiredParamaters)

  end function

  prototype._postClientEvents = function(queryParameters as Object)

    '   t - Taplytics API Key ● API Key
    '   sid - Session_id
    '   e - Array of events
    '     type - type of the event (String)
    '     gn - goal name (String)
    '     date - current date (Date)
    '     val - numerical value (Double)
    '     data - metaData (JSON Object)
    '     prod - is prod, not live update (Boolean)
    '     sid - session_id (String)

    requiredParamaters = {}

    requiredParamaters.t = m.KEY
    requiredParamaters.sid = m._clientConfig.sid

    'create array
    e = []

    'create event
    event = {}
    event.type = "goalAchieved"
    if queryParameters.DoesExist("eventName") and queryParameters.eventName <> ""
      event.gn = queryParameters.eventName
    end if

    date = CreateObject("roDateTime")
    event.date = date.ToISOString()
    print "event date : ", event.date

    if queryParameters.DoesExist("eventValue")
      event.val = queryParameters.eventValue
    end if
    if queryParameters.DoesExist("metadata")
      event.data = queryParameters.metadata
    end if
    if m._sessionProperties.is_dev
      event.prod = 0
    else
      event.prod = 1
    end if
    event.sid = m._clientConfig.sid

    'create array of only 1 event
    e.push(event)
    requiredParamaters.e = e

    api = "/v1/clientEvents/"
    method = "POST"
    name = "clientEvents"
    context = createObject("RoSGNode","Node")
    context.addFields({
        response: {}
    })
    context.observeField("response", m.httpPort)
    m._makeRequest(m.DEFAULT_PING_URL, api, method, name, context, {}, requiredParamaters)

  end function

  prototype._postResetAppUser = function()

    '   t - Taplytics API Key ● API Key
    '   sid - Session_id
    '   auid - AppUser ID
    '   ad - device adID identifier

    requiredParamaters = {}

    requiredParamaters.t = m.KEY
    requiredParamaters.sid = m._variables.sid
    requiredParamaters.auid = m._variables.au_id
    requiredParamaters.ad = m._sessionProperties.player_unique_id

    api = "/v1/resetAppUser/"
    method = "POST"
    name = "resetAppUser"
    context = createObject("RoSGNode","Node")
    context.addFields({
        response: {}
    })
    context.observeField("response", m.httpPort)
    m._makeRequest(m.DEFAULT_URL, api, method, name, context, {}, requiredParamaters)
  end function





  ' ' //////////////////////////////////////////////////////////////
  ' ' NETWORK APIs RESPONSE
  ' ' //////////////////////////////////////////////////////////////

  prototype._onGetClientConfig = function(msg as Object)
    if m._top.enablePrint then print "ENTER _onGetClientConfig>>>"
    if m._top.enablePrint then print msg
    if msg.code = 200
      content = msg.content
      m._clientConfig = ParseJSON(content)
      m._recurseOnClientConfig(m._clientConfig, "")
      m._top.clientConfig = m._variables
      if m._top.enablePrint then print m._variables
      m._clientConfigReady = true
    end if
  end function

  prototype._onPostClientAppUser = function(msg as Object)
    if m._top.enablePrint then print "ENTER _onPostClientAppUser>>>"
    if m._top.enablePrint then print msg
  end function

  prototype._onPostClientEvents = function(msg as Object)
    if m._top.enablePrint then print "ENTER _onPostClientEvents>>>"
    if m._top.enablePrint then print msg
  end function

  prototype._onPostResetAppUser = function(msg as Object)
    if m._top.enablePrint then print "ENTER _onPostResetAppUser>>>"
    if m._top.enablePrint then print msg
  end function


  ' ' //////////////////////////////////////////////////////////////
  ' ' INTERNAL METHODS
  ' ' //////////////////////////////////////////////////////////////

  prototype._makeRequest = function(host as String, api as String, method as String, name as String, context as Object, parameters = {} as Object, payload = {} as Object, timeout = -1 as Integer)
        if m._top.enablePrint then print "ENTER _makeRequest"

        retryCountdown% = m.HTTP_RETRIES

        if timeout = -1 then timeout = m.HTTP_TIMEOUT
        if m._top.enablePrint then print "use timeout ", stri(timeout)

        m.connection.AsyncCancel()

        'create url
        url = host + api

        'add parameter
        queryParameters = ""
        if parameters <> invalid
          for each parameter in parameters
            value = parameters[parameter]
            if type(value) = "String" or type(value) = "roString" then value = m.connection.Escape(value)
            if type(value) = "Integer" or type(value) = "roInteger" then value = Stri(value).trim()

            appender = "&"
            if queryParameters = "" then appender = "?"
            queryParameters = queryParameters + appender + parameter + "=" + value
          end for
          url = url + queryParameters
        end if
        m.connection.SetUrl(url)

        'add payload
        requestBody = ""
        if payload <> invalid then requestBody = FormatJson(payload)

        'se method
        if method = "POST" then m.connection.SetRequest("POST")

        if m._top.enablePrint then print "send url : [" + url + "]"
        if m._top.enablePrint then print "send body : " + requestBody

        while retryCountdown% > 0
          if method = "POST"
             m.connection.AsyncPostFromString(requestBody)
          else
            m.connection.AsyncGetToString()
          end if
          event = wait(timeout, m.httpPort)
          if type(event) = "roUrlEvent"
            print "[tap-analytics] Request success"
            context.response = {name: name, code: event.getResponseCode(), content: event.getString()}
            exit while
          else if event = invalid
            print "[tap-analytics] Request timeout event occurs. Reset connection"
            m.connection.AsyncCancel()
            ' reset the connection after a timeout
            m.connection = _createConnection(m.httpPort)
          else
            print "[tap-analytics] Request unknown port event"
          end if

          'log_error([m.className, " invalid uri: ", uri])
          retryCountdown% = retryCountdown% - 1
        end while
  end function

  prototype._recurseOnClientConfig = function(Node as Object, ParentKeyName as String)
    for each key in Node
      if type(Node[key]) = "roAssociativeArray"
        if m._top.enablePrint then print "key container [",key, "] value [",Node[key],"]"
        if key = "dynamicVars"
          dynamicVars = Node[key]
          for each dynamicVar in dynamicVars
            if m._top.enablePrint then print "key [",dynamicVars[dynamicVar].name, "] value [",dynamicVars[dynamicVar].value,"]"
            m._variables.AddReplace(dynamicVars[dynamicVar].name, dynamicVars[dynamicVar].value)
          end for
        else
          m._recurseOnClientConfig(Node[key], ParentKeyName + key)
        end if
      else
        if m._top.enablePrint then print "key [",key, "] value [",Node[key],"]"
        sKey = key.trim()
        m._variables.AddReplace(ParentKeyName + sKey, Node[key])
      end if
    end for
  end function

  ' called once per application session'
  prototype._getSessionProperites = function() as Object
    props = {}
    deviceInfo = m._getDeviceInfo()
    appInfo = m._getAppInfo()

    ' HARDCODED
    props.player_sequence_number = 1
    props.player_software_name = m.PLAYER_SOFTWARE_NAME
    props.player_software_version = Mid(deviceInfo.GetVersion(), 3, 4)
    props.player_model_number = deviceInfo.GetModel()
    props.player_tap_plugin_name = appInfo.GetTitle()
    props.is_dev = appInfo.IsDev()
    props.player_unique_id = deviceInfo.GetChannelClientId()
    props.viewer_application_name = "Roku"
    props.viewer_application_version = Mid(deviceInfo.GetVersion(), 3, 4)
    props.viewer_device_name = "Roku"
    props.viewer_os_family = "Roku"
    props.viewer_os_version = Mid(deviceInfo.GetVersion(), 3, 4)
    props.tap_api_version = m.TAP_API_VERSION
    props.application_version = appInfo.GetVersion()
    props.player_tap_plugin_version = m.TAP_SDK_VERSION
    props.player_country_code = deviceInfo.GetCountryCode()
    props.player_language_code = deviceInfo.GetCurrentLocale()
    props.player_time_zone = deviceInfo.GetTimeZone()
    props.player_connection_type = deviceInfo.GetConnectionType()
    videoMode = deviceInfo.GetVideoMode()
    props.player_width = m._getVideoPlaybackMetric(videoMode, "width")
    props.player_height = m._getVideoPlaybackMetric(videoMode, "height")
    props.player_is_fullscreen = m.PLAYER_IS_FULLSCREEN

    ' DEVICE INFO
    if deviceInfo.IsRIDADisabled() = true
      props.viewer_user_id = deviceInfo.GetChannelClientId()
    else
      props.viewer_user_id = deviceInfo.GetRIDA()
    end if
    return props
  end function

  prototype._getVideoPlaybackMetric = function (videoMode as String, metricType as String) as String
    result = ""
    metrics = {
      "480i":     {width: "720", height: "480", aspect: "4:3", refresh: "60 Hz", depth: "8 Bit"},
      "480p":    {width: "720", height: "480", aspect: "4:3", refresh: "60 Hz", depth: "8 Bit"},
      "576i25":  {width: "720", height: "576", aspect: "4:3", refresh: "25 Hz", depth: "8 Bit"},
      "576p50":  {width: "720", height: "576", aspect: "4:3", refresh: "50 Hz", depth: "8 Bit"},
      "576p60":  {width: "720", height: "576", aspect: "4:3", refresh: "60 Hz", depth: "8 Bit"},
      "720p50":  {width: "1280", height: "720 ", aspect: "16:9", refresh: "50 Hz", depth: "8 Bit"},
      "720p":    {width: "1280", height: "720 ", aspect: "16:9", refresh: "60 Hz", depth: "8 Bit"},
      "1080i50": {width: "1920", height: "1080", aspect: "16:9", refresh: "50 Hz", depth: "8 Bit"},
      "1080i":   {width: "1920", height: "1080", aspect: "16:9", refresh: "60 Hz", depth: "8 Bit"},
      "1080p24": {width: "1920", height: "1080", aspect: "16:9", refresh: "24 Hz", depth: "8 Bit"},
      "1080p25": {width: "1920", height: "1080", aspect: "16:9", refresh: "25 Hz", depth: "8 Bit"},
      "1080p30": {width: "1920", height: "1080", aspect: "16:9", refresh: "30 Hz", depth: "8 Bit"},
      "1080p50": {width: "1920", height: "1080", aspect: "16:9", refresh: "50 Hz", depth: "8 Bit"},
      "1080p":   {width: "1920", height: "1080", aspect: "16:9", refresh: "60 Hz", depth: "8 Bit"},
      "2160p25": {width: "3840", height: "2160", aspect: "16:9", refresh: "25 Hz", depth: "8 Bit"},
      "2160p24": {width: "3840", height: "2160", aspect: "16:9", refresh: "24 Hz", depth: "8 Bit"},
      "2160p30": {width: "3840", height: "2160", aspect: "16:9", refresh: "30 Hz", depth: "8 Bit"},
      "2160p50": {width: "3840", height: "2160", aspect: "16:9", refresh: "50 Hz", depth: "8 Bit"},
      "2160p60": {width: "3840", height: "2160", aspect: "16:9", refresh: "60 Hz", depth: "8 Bit"},
      "2160p24b10": {width: "3840", height: "2160", aspect: "16:9", refresh: "24 Hz", depth: "10 Bit"},
      "2160p25b10": {width: "3840", height: "2160", aspect: "16:9", refresh: "25 Hz", depth: "10 Bit"},
      "2160p50b10": {width: "3840", height: "2160", aspect: "16:9", refresh: "50 Hz", depth: "10 Bit"},
      "2160p30b10": {width: "3840", height: "2160", aspect: "16:9", refresh: "30 Hz", depth: "10 Bit"},
      "2160p60b10": {width: "3840", height: "2160", aspect: "16:9", refresh: "60 Hz", depth: "10 Bit"}
    }
    if metrics[videoMode] <> Invalid
      modeMetrics = metrics[videoMode]
      if modeMetrics[metricType] <> Invalid
        result = modeMetrics[metricType]
      end if
    end if
    return result
  end function

  prototype._getDeviceInfo = function() as Object
    return _createDeviceInfo()
  end function

  prototype._getAppInfo = function() as Object
    return _createAppInfo()
  end function

  prototype._getDateTime = function() as Object
    return CreateObject("roDateTime")
  end function

  return prototype
end function
