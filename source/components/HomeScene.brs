'//////////////////////////////////////////////////////////////////////////////
sub init()

	m.TaplyticsAPI = m.top.FindNode("TaplyticsAPI")
	m.TaplyticsAPI.callFunc("startTaplytics", {})
	variableValue = m.TaplyticsAPI.callFunc("getValueForVariable", {name: "Foo", default: "xxx"})
	print "variableValue(oninit) : ", variableValue 'SHOULD PRINT NOTREADY TEXT'

end sub

sub test()

	print "*****************************************************************"
	print "****************** getValueForVariable **************************"
	variableValue = m.TaplyticsAPI.callFunc("getValueForVariable", {name: "Foo", default: "xxx"})
	print "variableValue : ", variableValue
	print "*****************************************************************"

	print "*****************************************************************"
	print "****************** getRunningExperimentsAndVariations ***********"
	ExpAndVar = m.TaplyticsAPI.callFunc("getRunningExperimentsAndVariations")
	if ExpAndVar.FAILURE = invalid
		for each experiment in ExpAndVar.experiments
			print "experiment :", experiment
			print "variations :", ExpAndVar.experiments[experiment]
		end for
	end if
	print "*****************************************************************"

	print "*****************************************************************"
	print "****************** getVariationForExperiment ********************"
	getVariationForExperiment = m.TaplyticsAPI.callFunc("getVariationForExperiment", "Example")
	print "getVariationForExperiment : ",getVariationForExperiment
	print "*****************************************************************"

	print "*****************************************************************"
	print "****************** logEvent *************************************"
	m.TaplyticsAPI.callFunc("logEvent", {eventName: "goalTest"})
	print "*****************************************************************"

	print "*****************************************************************"
	print "****************** setUserAttributes ****************************"
	m.TaplyticsAPI.callFunc("setUserAttributes", {firstName: "XavierTestToto1"})
	print "*****************************************************************"

	print "*****************************************************************"
	print "****************** resetAppUser *********************************"
	m.TaplyticsAPI.callFunc("resetAppUser")
	print "*****************************************************************"

end sub
