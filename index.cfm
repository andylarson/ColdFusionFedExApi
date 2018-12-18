<!---
	Created 12/17/2018
	Created By Andy Larson

	Getting Started:
		STEP 1
			Sign up for a personal FedEx account: https://www.fedex.com/en-us/create-account.html
			Go to the developer resource center. https://www.fedex.com/en-us/developer.html
				- https://www.fedex.com/en-us/developer/web-services/process.html#develop
					- get your testing key, password, account Number, and meter number needed to connect to the API's

						fedexLiveUrl  = "https://ws.fedex.com/web-services";
						fedexTestUrl  = "https://wsbeta.fedex.com:443/web-services";
						key           = "";
						password      = "";
						accountNumber = "";
						meterNumber   = "";


		Step 2:
			Enter key, password, account Number, and meter number.

		Step 3
			Run a test.

	Notes:
		The FedEx API is NOT kept up to date very well.
		FedEx does not provide much for sample data.
		The wsbeta.fedex.com API allows the use of real tracking number, however I have found there to be a delay form production.

			TEST NUMBERS from PDF: "FedEx_WebServices_DevelopersGuide_v2018.pdf"
				Tracking Number    Scan Event
				---------------   ---------------------------------------------------------------------------------
				449044304137821    Shipment information sent to FedEx
				149331877648230    Tendered
				020207021381215    Picked Up
				403934084723025    Arrived at FedEx location
				920241085725456    At local FedEx facility
				568838414941       At destination sort facility
				039813852990618    Departed FedEx location
				231300687629630    On FedEx vehicle for delivery
				797806677146       International shipment release
				377101283611590    Customer not available or business closed (Delivery Exception 007)
				852426136339213    Local Delivery Restriction (Delivery Exception 083)
				797615467620       Incorrect Address (Delivery Exception 03)
				957794015041323    Unable to Deliver (Shipment Exception 099)
				076288115212522    Returned to Sender/Shipper
				581190049992       Clearance delay (International)
				122816215025810    Delivered
				843119172384577    Hold at Location
				070358180009382    Shipment Canceled

 --->



 <!DOCTYPE html>
<html>
	<head>
		<title>FEDEX API</title>
	</head>
	<body>

	<h1>FEDEX API</h1>
	<div style="border: 1px solid black; padding: 20px;">
		<b>Tracking</b>
		<form name="trackingForm" method="post" action="trackingResults.cfm">
			Tracking Number(s): <input type="input" id="trackingNumber" name="trackingNumber" value="122816215025810,020207021381215" style="width:300px;"><br><br>

			<input type="submit" name="trackingFormBtn" value="Track Number">
		</form>
	</div>
	<br><br>
	<div style="border: 1px solid black; padding: 20px;">
		<b>Shipping</b>
		<form name="trackingForm" method="post" action="shippingResults.cfm">
			Ship a Package:<br><br>

			<input type="submit" name="shippingFormBtn" value="Ship ME">
		</form>
	</div>
	<br><br>
	<div style="border: 1px solid black; padding: 20px;">
		<b>Shipping Return</b>
		<form name="trackingForm" method="post" action="returnResults.cfm">
			Return a Package:<br><br>

			<input type="submit" name="shippingFormBtn" value="Return ME">
		</form>
	</div>
	<br><br>
	<div style="border: 1px solid black; padding: 20px;">
		<b>Validate Address</b>
		<form name="validateAddressForm" method="post" action="validateAddress.cfm">
			Validate Address:<br><br>

			<input type="submit" name="validateAddressFormBtn" value="Validate ME">
		</form>
	</div>
	</body>
</html>
