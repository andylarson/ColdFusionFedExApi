<cfparam name="url.trackingNumber" default="">
<cfparam name="form.trackingNumber" default="#url.trackingNumber#">


<cfif len(trim(form.trackingNumber)) gt 0>
	<cfset trackData = createobject("component","fedEx").init().trackNumber(trackingNumber="#form.trackingNumber#")>
<cfelse>
	YOU MUST ENTER A TRACKING NUMBER!
</cfif>
