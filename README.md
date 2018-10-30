# Taplytics Roku SDK

An SDK for A/B Testing and analytics on Roku Channels

| Quick Access |
| ----------------- |
| [Installation & Initialization](#installation)|      
| [Experiment Information](#running-experiment-information)     |
| [Dynamic Variables](#dynamic-variables)         |
| [User Attributes](#setting-user-attributes)      |
| [Analytics](#analytics-events)|
| [Sessions](#sessions)|

------
# Installation

To add the Taplytics SDK to a roku channel, first copy the `taplytics` folder into the channel's `/components` directory.

### Initialization

Define the Taplytics API and SDK key in the scene component XML file of your channel:

```xml
<children>
<TaplyticsAPI
   id="TaplyticsAPI"
   key="90391ad033b0ffa48e36f0b4d5bacbe552b6f834" />
</children>
```

**Additional Options:**
`HTTP_RETRIES="5"`: The number of retries all HTTP calls will make if necessary. Default 5

Then, at the beginning of a Scene's BRS init function:

```brightscript
sub init()
	m.TaplyticsAPI = m.top.FindNode("TaplyticsAPI")
	m.TaplyticsAPI.callFunc("startTaplytics", {})
end sub
```

### Global Reference

Globally referencing the Taplytics SDK can be acheived by using a global data scoping. The implementation of this depends on the setup of your Roku channel. See the following for more information:

https://sdkdocs.roku.com/display/sdkdoc/SceneGraph+Data+Scoping


## Running Experiment Information


### Running Experiments and Variations

If you would like to see which variations and experiments are running on a given device, there exists a `getRunningExperimentsAndVariations` function which provides a map of the current experiments and their running variations. An example:

```
expVars = m.TaplyticsAPI.callFunc("getRunningExperimentsAndVariations")
print "Experiments And Variations: ", expVars
```

Output:

```
{
    "Experiment 1": "Variation 2"
    "My great experiment: "Variation 4"
}
```

### Specific Experiment Info

To get the variation a user is in for a specific experiment, simply use `getVariationForExperiment`. An example:

```
variation = m.TaplyticsAPI.callFunc("getVariationForExperiment", "Experiment Name")
print "Experiments And Variations: ", variation
```

Output:

```
"Variation Name"
```

## Dynamic Variables

Taplytics variables are values in your app that are controlled by experiments. Changing the values can update the content or functionality of your app. Variables are reusable between experiments and can be of type: boolean, number, string, or JSON.

To retrieve a variable's value, use the `getValueForVariable` method. 

The method takes two parameters: `name`, and `default`

For example: 

```brightscript
variableValue = m.TaplyticsAPI.callFunc("getValueForVariable", {name: "Foo", default: "Bar"})
print "variableValue : ", variableValue
```

Output (String example):

```
"Some variable Value"
```

The `name` parameter is the name of the variable set up in the dashboard

The `default` parameter is what the method will return if the user is not in an experiment containing the variable, or something goes wrong with the request.


## Setting User Attributes

It's possible to send custom user attributes to Taplytics using a JSONObject of user info. These attributes can be used to identify users as well as segment users into experiments on the Taplytics dashboard.

For example:

```
m.TaplyticsAPI.callFunc("setUserAttributes", {firstName: "YourNewName", user_id:"abcdefg"})
```

### Resetting user attributes or Logging out a user

Once a user logs out of your app, their User Attributes are no longer valid. You can reset their data by calling resetAppUser. This will get a new config for the user with updated experiment and variation data.

```
m.TaplyticsAPI.callFunc("resetAppUser")
```

## Analytics Events

To track events in Taplytics, use the `logEvent` function

```
m.TaplyticsAPI.callFunc("logEvent", {eventName: "eventName"})
```

These events will be tracked towards Goals in taplytics and will be available in all data exports.


## Sessions

By default, Taplytics defines a session as when a user is using the channel. If the user exits the channel and re-opens it, that will be considered a new session.

### Starting a New Session

To manually force a new user session (ex: A user has logged in / out), there exists Taplytics.startNewSession

If there is an internet connection, a new session will be created, and new experiments/variations will be fetched from Taplytics if they exist.

It can be used as follows:

```
m.TaplyticsAPI.callFunc("startNewSession")
```


