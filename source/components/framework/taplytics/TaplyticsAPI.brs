' ' //////////////////////////////////////////////////////////////
' ' PUBLIC APIs
' ' //////////////////////////////////////////////////////////////
'  01. startTaplytics
'  02. getRunningExperimentsAndVariations
'  03. getVariationForExperiment
'  04. getValueForVariable
'  05. getRunningFeatureFlags
'  06. getFeatureFlagEnabled
'  07. logEvent
'  08. resetUser
'  09. setUserAttributes
'  10. startNewSession
'  11. getSessionInfo

function init()
  m._clientConfig = invalid
  m._clientConfigReady = false
  m.TaplyticsPrivateAPI = m.top.findNode("TaplyticsPrivateAPI")
  m.TaplyticsPrivateAPI.ObserveField("clientConfig", "_onClientConfig")
  m.global.addFields({taplyticsInfo: {}, taplyticsReady: false})
end function

'*******************************************************************************
'*******************************************************************************
'*******************************************************************************
'*******************************************************************************
function getRunningExperimentsAndVariations() as Object
  return getExperimentsAndVariationsWithStatus("active")
end function


function getExperimentsAndVariationsWithStatus(status) as Object
  response = {}
  if m._clientConfigReady
    experiments = m._clientConfig["experiments"]
    if experiments <> invalid
      response.experiments = {}
      for each experiment in experiments
        if status = "all" or experiment.status = status then
          variations = experiment.variations
          arrayOfVar = []
          for each variation in variations
            arrayOfVar.push(variation.name)
          end for
          response.experiments.AddReplace(experiment.name, arrayOfVar)
        end if
      end for
    end if
  else
    response.FAILURE = true
  end if
  return response
end function

'*******************************************************************************
function getVariationForExperiment(experimentName as string) as Object
  if m.top.enablePrint then print "[Taplytics] ENTER getVariationForExperiment>>>"
  if m.top.enablePrint then print "[Taplytics] Experiment name --> ", experimentName
  response = invalid

  if m._clientConfigReady
    expN = m._clientConfig["expN"]
    if expN <> invalid
      for each experiment in expN
        if experiment.e = experimentName
          response = experiment.v
          exit for
        end if
      end for
    end if
  end if

  if m.top.enablePrint then print "[Taplytics] variant: ", response

  return response
end function

'*******************************************************************************
function getValueForVariable(params as Object) as dynamic

  if m.top.enablePrint then print "[Taplytics] ENTER getValueForVariable>>>"
  if m.top.enablePrint then print "[Taplytics] Variable name --> ", params.name
  if m.top.enablePrint then print "[Taplytics] Default value --> ", params.default

  value = params.default

  if m._clientConfigReady
    variable = m._clientConfig["dynamicVars." + params.name]
    if variable <> invalid
      if variable.isActive = true and variable.value <> invalid
        if m.top.enablePrint then print "[Taplytics] found active test variable --> ", variable.value
        value = variable.value
      end if
    end if
  end if

  if m.top.enablePrint then print "[Taplytics] Variable value: ", value

  return value
end function

'*******************************************************************************
function getRunningFeatureFlags() as Object
  if m.top.enablePrint then print "[Taplytics] ENTER getRunningFeatureFlags>>>"
  return getFeatureFlags("active")
end function

function getFeatureFlags(status = "all") as object
  if m.top.enablePrint then print "[Taplytics] ENTER getFeatures>>>"
  response = []

  if m._clientConfigReady
    features = m._clientConfig["ff"]
    if features <> invalid
      for each featureKey in features
        feature = features[featureKey]
        if status = "all" or status = feature.status
          temp = {
            variable: featureKey
          }
          temp.append(feature)
          if m.top.enablePrint then print "[Taplytics] feature variable: ", temp.name
          response.push(temp)
        end if
      end for
    end if
  end if

  return response
end function

'*******************************************************************************
function getFeatureFlagEnabled(params as Object) as boolean
  if m.top.enablePrint then print "[Taplytics] ENTER getFeatureFlagEnabled>>>"
  if m.top.enablePrint then print "[Taplytics] FF key --> ", params.key
  if m.top.enablePrint then print "[Taplytics] FF Default value --> ", params.default

  value = params.default

  if m._clientConfigReady
    feature = m._clientConfig["ff." + params.key]
    if feature <> invalid
      if feature.status = "active" and feature.enabled <> invalid
        if m.top.enablePrint then print "[Taplytics] found active feature flag --> ", feature.enabled
        value = feature.enabled
      end if
    end if
  end if

  return value
end function

'*******************************************************************************
function logEvent(params as Object) as Object
  if m.top.enablePrint then print "[Taplytics] ENTER logEvent>>>"
  if m.top.enablePrint then print "[Taplytics] Event name --> ", params.eventName
  if m.top.enablePrint and params.eventValue <> invalid then print "[Taplytics] Event value --> ", params.eventValue
  m.TaplyticsPrivateAPI.logEvent = params
end function

'*******************************************************************************
function resetUser() as Object
  if m.top.enablePrint then print "[Taplytics] ENTER resetUser>>>"
  m.TaplyticsPrivateAPI.resetAppUser = true
end function

'*******************************************************************************
function setUserAttributes(params as Object) as Object
  if m.top.enablePrint then print "[Taplytics] ENTER setUserAttributes>>>"
  m.TaplyticsPrivateAPI.setUserAttributes = params
end function

'*******************************************************************************
function startNewSession() as Object
  if m.top.enablePrint then print "[Taplytics] ENTER startNewSession>>>"
  m.TaplyticsPrivateAPI.startTaplytics = {}
end function

'*******************************************************************************
function getSessionInfo() as Object
  if m.top.enablePrint then print "[Taplytics] ENTER getSessionInfo>>>"
  return m.TaplyticsPrivateAPI.startTaplytics
end function

'*******************************************************************************
function startTaplytics(params as Object) as Object
  if m.top.enablePrint then print "[Taplytics] ENTER startTaplytics>>>"
  m.TaplyticsPrivateAPI.startTaplytics = params
end function

'*******************************************************************************
'*******************************************************************************
'*******************************************************************************
'*******************************************************************************
function _onClientConfig()
  if m.top.enablePrint then print "[Taplytics] ENTER _onClientConfig>>>"
  m._clientConfig = m.TaplyticsPrivateAPI.clientConfig
  m._clientConfigReady = true

  taplyticsInfo = {
    experiments: []
    variables: {}
    features: {}
  }

  featureArray = []

  features = m._clientConfig["ff"]
  if features <> invalid
    for each featureKey in features
      feature = features[featureKey]
      if feature.status = "active"
        featureEntry = { variable: featureKey }
        featureEntry.append(feature)
        taplyticsInfo.features[featureKey] = featureEntry

        'make an array of names so we can filter them from expN
        featureArray.push(featureEntry.name)
      end if
    end for
  end if

  variables = m._clientConfig["dynamicVars"]
  if variables <> invalid
    for each variable in variables
      var = variables[variable]
      if var <> invalid and var.isActive = true
        taplyticsInfo.variables[variable] = var
      end if
    end for
  end if

  expN = m._clientConfig["expN"]
  if expN <> invalid
    for each experiment in expN
      ' Only put experiments into this.  Feature Flags should not be included in the experiments array, so they don't get added to the GA dimensions.
      if not _arrayHasValue(featureArray, experiment.e)
        expEntry = { name: experiment.e, variant: experiment.v }
        taplyticsInfo.experiments.push(expEntry)
      end if
    end for
  end if

  if m.top.enablePrint then print "[Taplytics] Setting Taplytics Info global:"

  m.global.taplyticsInfo = taplyticsInfo
  m.global.taplyticsReady = true
  m.top.ready = true
end function

function _arrayHasValue(objects, value) as boolean
  if objects = invalid then return false

  for each obj in objects
    if obj = value then return true
  end for

  return false
end function
