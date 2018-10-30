function init()
  m._clientConfig = invalid
  m._clientConfigReady = false
  m.TaplyticsPrivateAPI = m.top.findNode("TaplyticsPrivateAPI")
  m.TaplyticsPrivateAPI.ObserveField("clientConfig", "_onClientConfig")
end function

'*******************************************************************************
'*******************************************************************************
'*******************************************************************************
'*******************************************************************************
function getRunningExperimentsAndVariations() as object
  response = {}
  if m._clientConfigReady
    if m._clientConfig.DoesExist("experiments")
      experiments = m._clientConfig["experiments"]
      response.experiments = {}
      for each experiment in experiments
        variations = experiment.variations
        arrayOfVar = []
        for each variation in variations
          arrayOfVar.push(variation.name)
        end for
        response.experiments.AddReplace(experiment.name, arrayOfVar)
      end for
    end if
  else
    response.FAILURE = true
  end if
  return response
end function

'*******************************************************************************
function getValueForVariable(params as Object) as Object

  if m.top.enablePrint then print "ENTER getValueForVariable>>>"
  if m.top.enablePrint then print "Variable name --> ",params.name
  if m.top.enablePrint then print "Default value --> ",params.default

  value = "NOTREADY"
  if m._clientConfigReady
    value = params.default
    if m._clientConfig.DoesExist(params.name) then value = m._clientConfig[params.name]
  end if
  return value
end function

'*******************************************************************************
function getVariationForExperiment(experimentName as String) as object
  if m.top.enablePrint then print "ENTER getVariationForExperiment>>>"
  if m.top.enablePrint then print "Experiment name --> ",experimentName
  response = invalid

  if m._clientConfigReady
    if m._clientConfig.DoesExist("experiments")
      experiments = m._clientConfig["expN"]
      if m.top.enablePrint then print "list of experiments : ", experiments
      for each experiment in experiments
        if m.top.enablePrint then print "experiment :", experiment
        if experiment.e = experimentName
          response = experiment.v
          exit for
        end if
      end for
    end if
  end if
  return response
end function

'*******************************************************************************
function logEvent(params as Object) as Object
  if m.top.enablePrint then print "ENTER logEvent>>>"
  if m.top.enablePrint then print "Event name --> ",params.eventName
  if m.top.enablePrint and params.eventValue <> invalid then print "Event value --> ",stri(params.eventValue)
  m.TaplyticsPrivateAPI.logEvent = params
end function

'*******************************************************************************
function resetAppUser() as Object
  if m.top.enablePrint then print "ENTER resetAppUser>>>"
  m.TaplyticsPrivateAPI.resetAppUser = true
  m.TaplyticsPrivateAPI.startTaplytics = {}
end function

'*******************************************************************************
function setUserAttributes(params as Object) as Object
  if m.top.enablePrint then print "ENTER setUserAttributes>>>"
  m.TaplyticsPrivateAPI.setUserAttributes = params
end function

'*******************************************************************************
function startNewSession() as Object
  if m.top.enablePrint then print "ENTER startNewSession>>>"
  m.TaplyticsPrivateAPI.startTaplytics = {}
end function

'*******************************************************************************
function startTaplytics(params as Object) as Object
  if m.top.enablePrint then print "ENTER startTaplytics>>>"
  m.TaplyticsPrivateAPI.startTaplytics = params
end function

'*******************************************************************************
'*******************************************************************************
'*******************************************************************************
'*******************************************************************************
function _onClientConfig()
  if m.top.enablePrint then print "ENTER _onClientConfig>>>"
  m._clientConfig = m.TaplyticsPrivateAPI.clientConfig
  m._clientConfigReady = true
end function
