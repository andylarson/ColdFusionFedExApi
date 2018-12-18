component accessors="true" output="false" hint="component related to FedEx Stuff" {

	function init() {
			// variables.fedexUrl   = "https://ws.fedex.com/web-services";
			variables.fedexUrl  = "https://wsbeta.fedex.com:443/web-services";
			variables.key       = "";
			variables.password  = "";
			variables.accountNo = "";
			variables.meterNo   = "";

			return this;
		}


		function trackNumber(required string trackingNumber) {
			var local                   = {};
			local.result                = {};
			local.result.TrackingData   = arrayNew(1);
			local.TrackingStruct        = {};
			local.TrackingEvents        = {};
			local.result.success        = false;
			local.XMLPacket             = "";


			writeOutput('Submitted Tracking Number: #arguments.trackingNumber# <br><br>');

			// Build the XML Packet to send to FedEx

			local.XMLPacket = local.XMLPacket & '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://fedex.com/ws/track/v16">';
			local.XMLPacket = local.XMLPacket & ' <soapenv:Header/>';
				local.XMLPacket = local.XMLPacket & ' <soapenv:Body>';
					local.XMLPacket = local.XMLPacket & ' <ns:TrackRequest>';
						local.XMLPacket = local.XMLPacket & ' <ns:WebAuthenticationDetail>';
							local.XMLPacket = local.XMLPacket & ' <ns:UserCredential>';
								local.XMLPacket = local.XMLPacket & ' <ns:Key>#variables.key#</ns:Key>';
								local.XMLPacket = local.XMLPacket & ' <ns:Password>#variables.password#</ns:Password>';
							local.XMLPacket = local.XMLPacket & ' </ns:UserCredential>';
						local.XMLPacket = local.XMLPacket & ' </ns:WebAuthenticationDetail>';
						local.XMLPacket = local.XMLPacket & ' <ns:ClientDetail>';
							local.XMLPacket = local.XMLPacket & ' <ns:AccountNumber>#variables.accountNo#</ns:AccountNumber>';
							local.XMLPacket = local.XMLPacket & ' <ns:MeterNumber>#variables.meterNo#</ns:MeterNumber>';
						local.XMLPacket = local.XMLPacket & ' </ns:ClientDetail>';
						local.XMLPacket = local.XMLPacket & ' <ns:TransactionDetail>';
							local.XMLPacket = local.XMLPacket & ' <ns:CustomerTransactionId>Track By Number_v16</ns:CustomerTransactionId>';
							local.XMLPacket = local.XMLPacket & ' <ns:Localization>';
								local.XMLPacket = local.XMLPacket & ' <ns:LanguageCode>EN</ns:LanguageCode>';
								local.XMLPacket = local.XMLPacket & ' <ns:LocaleCode>US</ns:LocaleCode>';
							local.XMLPacket = local.XMLPacket & ' </ns:Localization>';
						local.XMLPacket = local.XMLPacket & ' </ns:TransactionDetail>';
						local.XMLPacket = local.XMLPacket & ' <ns:Version>';
							local.XMLPacket = local.XMLPacket & ' <ns:ServiceId>trck</ns:ServiceId>';
							local.XMLPacket = local.XMLPacket & ' <ns:Major>16</ns:Major>';
							local.XMLPacket = local.XMLPacket & ' <ns:Intermediate>0</ns:Intermediate>';
							local.XMLPacket = local.XMLPacket & ' <ns:Minor>0</ns:Minor>';
						local.XMLPacket = local.XMLPacket & ' </ns:Version>';

						/*
							Loop over tracking number(s). Using bulk tracking number look up for returns
							Batch Tracking
								- The maximum number of packages within a single track transaction is limited to 30.
						*/
						for (local.TrackingNum in listToArray(arguments.trackingNumber, ",")) {
							local.XMLPacket = local.XMLPacket & ' <ns:SelectionDetails>';
								local.XMLPacket = local.XMLPacket & ' <ns:PackageIdentifier>';
									local.XMLPacket = local.XMLPacket & ' <ns:Type>TRACKING_NUMBER_OR_DOORTAG</ns:Type>';
									local.XMLPacket = local.XMLPacket & ' <ns:Value>#local.TrackingNum#</ns:Value>';
								local.XMLPacket = local.XMLPacket & ' </ns:PackageIdentifier>';
							local.XMLPacket = local.XMLPacket & ' </ns:SelectionDetails>';
						}

						// Comment out if you do not need detailed information.
						local.XMLPacket = local.XMLPacket & ' <ns:ProcessingOptions>INCLUDE_DETAILED_SCANS</ns:ProcessingOptions>';

					local.XMLPacket = local.XMLPacket & ' </ns:TrackRequest>';

				local.XMLPacket = local.XMLPacket & ' </soapenv:Body>';

			local.XMLPacket = local.XMLPacket & ' </soapenv:Envelope>';



			writeOutput("XML POST: ");
			writeDump(local.XMLPacket);

			local.httpService = new http(method="POST", charset="utf-8", url="#variables.fedexurl#/track");
				httpService.addParam(name="name", type="XML", value="#local.XMLPacket#");
			local.httpResult = local.httpService.send().getPrefix();

			writeOutput('<br><br> httpResult FileContent:');
			writeDump(local.httpResult.FileContent);

			local.xmlFile = XmlParse(local.httpResult.FileContent).Envelope.Body;
			writeOutput('<br><br> RESULTS:');
			writeDump(local.xmlFile);



			if (local.xmlfile.TrackReply.HighestSeverity.xmltext eq 'SUCCESS' && local.xmlfile.TrackReply.Notifications.Severity.xmltext eq 'SUCCESS') {

				if (local.xmlfile.TrackReply.CompletedTrackDetails.HighestSeverity.xmltext eq 'SUCCESS') {

					if (local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails.Notification.Severity.xmltext eq 'SUCCESS') {

						// Contains detailed tracking information for the requested packages(s).
						for (var i=1; i LTE ArrayLen(local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails); i=i+1) {

							// reset the structure
							local.TrackingStruct = {};

							// Entered Tracking Number, FedEx assigned identifier for a package/shipment.
							// needs to come from xml for master child records
							local.TrackingStruct.trackingNumber = local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].TrackingNumber.XmlText;

							// When duplicate tracking numbers exist this data is returned with summary information for each of the duplicates.
							// The summary information is used to determine which of the duplicates the intended tracking number is.
							// This identifier is used on a subsequent track request to retrieve the tracking data for the desired tracking number.
							local.TrackingStruct.trackingNumberUniqueIdentifier = local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].trackingNumberUniqueIdentifier.XmlText;

							local.TrackingStruct.statusDetailCreationTime = "";
							local.TrackingStruct.statusDetailCode = "";
							local.TrackingStruct.statusDetailDescription = "";
							local.TrackingStruct.ancillaryDetailsReason = "";
							local.TrackingStruct.ancillaryDetailsReasonDescription = "";
							local.TrackingStruct.ancillaryDetailsAction = "";
							local.TrackingStruct.ancillaryDetailsActionDescription = "";
							local.TrackingStruct.ServiceCommitMessage = "";

							//Specify details about the status of the shipment being tracked.
							if (structKeyExists(local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i], "StatusDetail")) {
								//An ISO8601DateTime.
								if (structKeyExists(local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].StatusDetail, "CreationTime")) {
									local.TrackingStruct.statusDetailCreationTime = local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].StatusDetail.CreationTime.XmlText;
								}
								//A code that identifies this type of status.
								if (structKeyExists(local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].StatusDetail, "code")) {
									local.TrackingStruct.statusDetailCode =  local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].StatusDetail.code.XmlText;
								}
								//A human-readable description of this status.
								if (structKeyExists(local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].StatusDetail, "Description")) {
									local.TrackingStruct.statusDetailDescription = local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].StatusDetail.Description.XmlText;
								}

								//Descriptive information about the shipment status. May be used as an actual physical address — place to which one could go — or as a container of "address parts," which should be handled as a unit, such as city-state-ZIP combination within the U.S.
								if (structKeyExists(local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].StatusDetail, "AncillaryDetails")) {
									if (structKeyExists(local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].StatusDetail.AncillaryDetails, "Reason")) {
										local.TrackingStruct.ancillaryDetailsReason = local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].StatusDetail.AncillaryDetails.Reason.XmlText;
									}

									if (structKeyExists(local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].StatusDetail.AncillaryDetails, "ReasonDescription")) {
										local.TrackingStruct.ancillaryDetailsReasonDescription = local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].StatusDetail.AncillaryDetails.ReasonDescription.XmlText;
									}

									if (structKeyExists(local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].StatusDetail.AncillaryDetails, "Action")) {
										local.TrackingStruct.ancillaryDetailsAction = local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].StatusDetail.AncillaryDetails.Action.XmlText;
									}

									if (structKeyExists(local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].StatusDetail.AncillaryDetails, "ActionDescription")) {
										local.TrackingStruct.ancillaryDetailsActionDescription = local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].StatusDetail.AncillaryDetails.ActionDescription.XmlText;
									}
								}
							}

							// Used to convey information such as:
							// • FedEx has received information about a package but has not yet taken possession of it.
							// • FedEx has handed the package off to a third party for final delivery.
							// • The package delivery has been cancelled.
							if (structKeyExists(local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i], "ServiceCommitMessage")) {
								local.TrackingStruct.ServiceCommitMessage = local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].ServiceCommitMessage.XmlText;
							}



							// Identification of a FedEx operating company (transportation).
							local.TrackingStruct.CarrierCode = local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].CarrierCode.XmlText;

							local.TrackingStruct.estimatedDeliveryDate = "";

							if (structKeyExists(local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i], "DatesOrTimes") and arrayLen(local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].DatesOrTimes) gt 0) {
								for (var t=1; t LTE ArrayLen(local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].DatesOrTimes); t=t+1) {
									local.result.success=true;
									local.TrackingDatesOrTimes = {};

										// - ACTUAL_DELIVERY
										// - ACTUAL_PICKUP
										// - ACTUAL_TENDER
										// - ANTICIPATED_TENDER (Replaces ShipTimestamp)
										// - APPOINTMENT_DELIVERY (Replaces AppointmentDeliveryTimestamp)
										// - COMMITMENT (Replaces commitmentTimestamp)
										// - ESTIMATED_ARRIVAL_AT_GATEWAY (Replaces estimatedArrivalAtGatewayTimestamp)
										// - ESTIMATED_DELIVERY (Replaces estimatedDeliveryTimestamp)
										// - ESTIMATED_PICKUP (Replaces estimatedPickupTimestamp)
										// - SHIP (Replaces shipTimestamp)


									// ESTIMATED_DELIVERY DATE
									if (local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].DatesOrTimes[t].Type.XmlText eq "ESTIMATED_DELIVERY") {
										local.TrackingStruct.estimatedDeliveryDate = local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].DatesOrTimes[t].DateOrTimestamp.XmlText;
									}
								}
							} else {
								// Missing DatesOrTimes information.";
							}


							local.TrackingStruct.events = arrayNew(1);

							// https://www.fedex.com/us/developer/downloads/xml/2018/standard/TrackService_v16.xsd
							// Event information for a tracking number.
								// <Events>
								//  <Timestamp>2014-01-07T19:37:00-07:00</Timestamp>
								//  <EventType>AR</EventType>
								//  <EventDescription>At destination sort facility</EventDescription>
								//  <Address>
								//      <City>PHOENIX</City>
								//      <StateOrProvinceCode>AZ</StateOrProvinceCode>
								//      <PostalCode>85034</PostalCode>
								//      <CountryCode>US</CountryCode>
								//      <CountryName>United States</CountryName>
								//      <Residential>false</Residential>
								//  </Address>
								//  <ArrivalLocation>SORT_FACILITY</ArrivalLocation>
								// </Events>

							if (structKeyExists(local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i], "Events") and arrayLen(local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].Events) gt 0) {
								for (var e=1; e LTE ArrayLen(local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].Events); e=e+1) {

									local.TrackingEvents = {};

									//Carrier's scan code. Pairs with EventDescription.
									local.TrackingEvents.eventType = local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].Events[e].EventType.XmlText;

									// Literal description that pairs with the EventType.
									local.TrackingEvents.eventDescription = local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].Events[e].EventDescription.XmlText;

									// Indicates where the arrival actually occurred.
									local.TrackingEvents.arrivalLocation = local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].Events[e].ArrivalLocation.XmlText;

									// The time this event occurred.
									local.TrackingEvents.Timestamp = local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].Events[e].Timestamp.XmlText;

									// Further defines the Scan Type code's specific type (e.g., DEX08 business closed). Pairs with StatusExceptionDescription.
									local.TrackingEvents.StatusExceptionCode = "";
									if (structKeyExists(local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].Events[e], "StatusExceptionCode")){
										local.TrackingEvents.StatusExceptionCode = local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].Events[e].StatusExceptionCode.XmlText;
									}

									// Literal description that pairs with the StatusExceptionCode.
									local.TrackingEvents.StatusExceptionDescription = "";
									if (structKeyExists(local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].Events[e], "StatusExceptionDescription")){
										local.TrackingEvents.StatusExceptionDescription = local.xmlfile.TrackReply.CompletedTrackDetails.TrackDetails[i].Events[e].StatusExceptionDescription.XmlText;
									}

									arrayAppend(local.TrackingStruct.events, local.TrackingEvents);
								}

								arrayAppend(local.result.TrackingData, local.TrackingStruct);

								local.result.success=true;
							} else {
								// Missing event information.";
							}
						}

					} else {
						// If there is a failure or error notification at the TrackDetails level then ignore the remaining response/payload.
					}

				} else {
					// If there is a failure or error notification at the CompletedTrackDetails level then ignore the remaining response/payload.
				}
			} else {

				// If there is a failure or error notification at the method level (TrackReply/Notifications) then ignore the remaining response/payload.
				/* Bad Login or service unaviable */
			}


			writeDump(local.result);


			return local.result;
		}


		function shipLabel() {
			var local       = {};
			local.result    = {};
			local.XMLPacket = "";

			local.XMLPacket = local.XMLPacket & '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://fedex.com/ws/ship/v23">';
				local.XMLPacket = local.XMLPacket & '<soapenv:Header/>';
				local.XMLPacket = local.XMLPacket & '<soapenv:Body>';
					local.XMLPacket = local.XMLPacket & '<ns:ProcessShipmentRequest>';
						local.XMLPacket = local.XMLPacket & '<ns:WebAuthenticationDetail>';
							local.XMLPacket = local.XMLPacket & '<ns:UserCredential>';
								local.XMLPacket = local.XMLPacket & '<ns:Key>#variables.key#</ns:Key>';
								local.XMLPacket = local.XMLPacket & '<ns:Password>#variables.password#</ns:Password>';
							local.XMLPacket = local.XMLPacket & '</ns:UserCredential>';
						local.XMLPacket = local.XMLPacket & '</ns:WebAuthenticationDetail>';
						local.XMLPacket = local.XMLPacket & '<ns:ClientDetail>';
							local.XMLPacket = local.XMLPacket & '<ns:AccountNumber>#variables.accountNo#</ns:AccountNumber>';
							local.XMLPacket = local.XMLPacket & '<ns:MeterNumber>#variables.meterNo#</ns:MeterNumber>';
						local.XMLPacket = local.XMLPacket & '</ns:ClientDetail>';
						local.XMLPacket = local.XMLPacket & '<ns:TransactionDetail>';
							local.XMLPacket = local.XMLPacket & '<ns:CustomerTransactionId></ns:CustomerTransactionId>';
						local.XMLPacket = local.XMLPacket & '</ns:TransactionDetail>';
						local.XMLPacket = local.XMLPacket & '<ns:Version>';
							local.XMLPacket = local.XMLPacket & '<ns:ServiceId>ship</ns:ServiceId>';
							local.XMLPacket = local.XMLPacket & '<ns:Major>23</ns:Major>';
							local.XMLPacket = local.XMLPacket & '<ns:Intermediate>0</ns:Intermediate>';
							local.XMLPacket = local.XMLPacket & '<ns:Minor>0</ns:Minor>';
						local.XMLPacket = local.XMLPacket & '</ns:Version>';
						local.XMLPacket = local.XMLPacket & '<ns:RequestedShipment>';
							local.XMLPacket = local.XMLPacket & '<ns:ShipTimestamp>2018-11-21T08:07:56-06:00</ns:ShipTimestamp>';
							local.XMLPacket = local.XMLPacket & '<ns:DropoffType>REGULAR_PICKUP</ns:DropoffType>';
							local.XMLPacket = local.XMLPacket & '<ns:ServiceType>STANDARD_OVERNIGHT</ns:ServiceType>';
							local.XMLPacket = local.XMLPacket & '<ns:PackagingType>YOUR_PACKAGING</ns:PackagingType>';
							local.XMLPacket = local.XMLPacket & '<ns:Shipper>';
								local.XMLPacket = local.XMLPacket & '<ns:AccountNumber>#variables.accountNo#</ns:AccountNumber>';
								local.XMLPacket = local.XMLPacket & '<ns:Contact>';
									local.XMLPacket = local.XMLPacket & '<ns:PersonName>Name</ns:PersonName>';
									local.XMLPacket = local.XMLPacket & '<ns:CompanyName></ns:CompanyName>';
									local.XMLPacket = local.XMLPacket & '<ns:PhoneNumber>123-456-7890</ns:PhoneNumber>';
									local.XMLPacket = local.XMLPacket & '<ns:EMailAddress>ShipperEmail@ShipperEmail.com</ns:EMailAddress>';
								local.XMLPacket = local.XMLPacket & '</ns:Contact>';
								local.XMLPacket = local.XMLPacket & '<ns:Address>';
									local.XMLPacket = local.XMLPacket & '<ns:StreetLines>111 1st Avenue North</ns:StreetLines>';
									local.XMLPacket = local.XMLPacket & '<ns:City>Minneapolis</ns:City>';
									local.XMLPacket = local.XMLPacket & '<ns:StateOrProvinceCode>MN</ns:StateOrProvinceCode>';
									local.XMLPacket = local.XMLPacket & '<ns:PostalCode>55401</ns:PostalCode>';
									local.XMLPacket = local.XMLPacket & '<ns:CountryCode>US</ns:CountryCode>';
								local.XMLPacket = local.XMLPacket & '</ns:Address>';
							local.XMLPacket = local.XMLPacket & '</ns:Shipper>';
							local.XMLPacket = local.XMLPacket & '<ns:Recipient>';
								local.XMLPacket = local.XMLPacket & '<ns:AccountNumber>#variables.accountNo#</ns:AccountNumber>';
								local.XMLPacket = local.XMLPacket & '<ns:Contact>';
									local.XMLPacket = local.XMLPacket & '<ns:PersonName>NAme</ns:PersonName>';
									local.XMLPacket = local.XMLPacket & '<ns:CompanyName></ns:CompanyName>';
									local.XMLPacket = local.XMLPacket & '<ns:PhoneNumber>123-456-7890</ns:PhoneNumber>';
									local.XMLPacket = local.XMLPacket & '<ns:EMailAddress>Recipient@Recipient.com</ns:EMailAddress>';
								local.XMLPacket = local.XMLPacket & '</ns:Contact>';
								local.XMLPacket = local.XMLPacket & '<ns:Address>';
									local.XMLPacket = local.XMLPacket & '<ns:StreetLines>111 1st Avenue North</ns:StreetLines>';
									local.XMLPacket = local.XMLPacket & '<ns:City>Minneapolis</ns:City>';
									local.XMLPacket = local.XMLPacket & '<ns:StateOrProvinceCode>MN</ns:StateOrProvinceCode>';
									local.XMLPacket = local.XMLPacket & '<ns:PostalCode>55401</ns:PostalCode>';
									local.XMLPacket = local.XMLPacket & '<ns:CountryCode>US</ns:CountryCode>';
								local.XMLPacket = local.XMLPacket & '</ns:Address>';
							local.XMLPacket = local.XMLPacket & '</ns:Recipient>';
							local.XMLPacket = local.XMLPacket & '<ns:ShippingChargesPayment>';
								local.XMLPacket = local.XMLPacket & '<ns:PaymentType>SENDER</ns:PaymentType>';
								local.XMLPacket = local.XMLPacket & '<ns:Payor>';
									local.XMLPacket = local.XMLPacket & '<ns:ResponsibleParty>';
										local.XMLPacket = local.XMLPacket & '<ns:AccountNumber>#variables.accountNo#</ns:AccountNumber>';
										local.XMLPacket = local.XMLPacket & '<ns:Contact>';
											local.XMLPacket = local.XMLPacket & '<ns:PersonName>Name</ns:PersonName>';
											local.XMLPacket = local.XMLPacket & '<ns:EMailAddress>ResponsibleParty@ResponsibleParty.com</ns:EMailAddress>';
										local.XMLPacket = local.XMLPacket & '</ns:Contact>';
									local.XMLPacket = local.XMLPacket & '</ns:ResponsibleParty>';
								local.XMLPacket = local.XMLPacket & '</ns:Payor>';
							local.XMLPacket = local.XMLPacket & '</ns:ShippingChargesPayment>';
							local.XMLPacket = local.XMLPacket & '<ns:LabelSpecification>';
								local.XMLPacket = local.XMLPacket & '<ns:LabelFormatType>COMMON2D</ns:LabelFormatType>';
								local.XMLPacket = local.XMLPacket & '<ns:ImageType>PNG</ns:ImageType>';
							local.XMLPacket = local.XMLPacket & '</ns:LabelSpecification>';
							local.XMLPacket = local.XMLPacket & '<ns:RateRequestTypes>LIST</ns:RateRequestTypes>';
							local.XMLPacket = local.XMLPacket & '<ns:PackageCount>2</ns:PackageCount>';
							local.XMLPacket = local.XMLPacket & '<ns:RequestedPackageLineItems>';
								local.XMLPacket = local.XMLPacket & '<ns:SequenceNumber>1</ns:SequenceNumber>';
								local.XMLPacket = local.XMLPacket & '<ns:Weight>';
									local.XMLPacket = local.XMLPacket & '<ns:Units>LB</ns:Units>';
									local.XMLPacket = local.XMLPacket & '<ns:Value>40</ns:Value>';
								local.XMLPacket = local.XMLPacket & '</ns:Weight>';
								local.XMLPacket = local.XMLPacket & '<ns:Dimensions>';
									local.XMLPacket = local.XMLPacket & '<ns:Length>5</ns:Length>';
									local.XMLPacket = local.XMLPacket & '<ns:Width>5</ns:Width>';
									local.XMLPacket = local.XMLPacket & '<ns:Height>5</ns:Height>';
									local.XMLPacket = local.XMLPacket & '<ns:Units>IN</ns:Units>';
								local.XMLPacket = local.XMLPacket & '</ns:Dimensions>';
								local.XMLPacket = local.XMLPacket & '<ns:PhysicalPackaging>BAG</ns:PhysicalPackaging>';
								local.XMLPacket = local.XMLPacket & '<ns:ItemDescription>Book</ns:ItemDescription>';
								local.XMLPacket = local.XMLPacket & '<ns:CustomerReferences>';
									local.XMLPacket = local.XMLPacket & '<ns:CustomerReferenceType>CUSTOMER_REFERENCE</ns:CustomerReferenceType>';
									local.XMLPacket = local.XMLPacket & '<ns:Value>NAFTA_COO</ns:Value>';
								local.XMLPacket = local.XMLPacket & '</ns:CustomerReferences>';
							local.XMLPacket = local.XMLPacket & '</ns:RequestedPackageLineItems>';
						local.XMLPacket = local.XMLPacket & '</ns:RequestedShipment>';
					local.XMLPacket = local.XMLPacket & '</ns:ProcessShipmentRequest>';
				local.XMLPacket = local.XMLPacket & '</soapenv:Body>';
			local.XMLPacket = local.XMLPacket & '</soapenv:Envelope>';

			writeOutput("XML POST: ");
			writeDump(local.XMLPacket);

			local.httpService = new http(method="POST", charset="utf-8", url="#variables.fedexurl#/ship");
				httpService.addParam(name="name", type="XML", value="#local.XMLPacket#");
			local.httpResult = local.httpService.send().getPrefix();

			writeOutput('<br><br> httpResult FileContent:');
			writeDump(local.httpResult.FileContent);

			local.xmlFile = XmlParse(local.httpResult.FileContent).Envelope.Body;

			writeOutput('<br><br> RESULTS:');
			cfimage (action="writeToBrowser", source=ToBinary(local.xmlFile.ProcessShipmentReply.CompletedShipmentDetail.CompletedPackageDetails.label.Parts.Image.XmlText));

			return local.result;
		}


		function returnLabel() {
			var local       = {};
			local.result    = {};
			local.XMLPacket = "";

			local.XMLPacket = local.XMLPacket & '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://fedex.com/ws/ship/v23">';
				local.XMLPacket = local.XMLPacket & '<soapenv:Header/>';
				local.XMLPacket = local.XMLPacket & '<soapenv:Body>';
					local.XMLPacket = local.XMLPacket & '<ns:ProcessShipmentRequest>';
						local.XMLPacket = local.XMLPacket & '<ns:WebAuthenticationDetail>';
							local.XMLPacket = local.XMLPacket & '<ns:UserCredential>';
								local.XMLPacket = local.XMLPacket & '<ns:Key>#variables.key#</ns:Key>';
								local.XMLPacket = local.XMLPacket & '<ns:Password>#variables.password#</ns:Password>';
							local.XMLPacket = local.XMLPacket & '</ns:UserCredential>';
						local.XMLPacket = local.XMLPacket & '</ns:WebAuthenticationDetail>';
						local.XMLPacket = local.XMLPacket & '<ns:ClientDetail>';
							local.XMLPacket = local.XMLPacket & '<ns:AccountNumber>#variables.accountNo#</ns:AccountNumber>';
							local.XMLPacket = local.XMLPacket & '<ns:MeterNumber>#variables.meterNo#</ns:MeterNumber>';
						local.XMLPacket = local.XMLPacket & '</ns:ClientDetail>';
						local.XMLPacket = local.XMLPacket & '<ns:TransactionDetail>';
							local.XMLPacket = local.XMLPacket & '<ns:CustomerTransactionId></ns:CustomerTransactionId>';
						local.XMLPacket = local.XMLPacket & '</ns:TransactionDetail>';
						local.XMLPacket = local.XMLPacket & '<ns:Version>';
							local.XMLPacket = local.XMLPacket & '<ns:ServiceId>ship</ns:ServiceId>';
							local.XMLPacket = local.XMLPacket & '<ns:Major>23</ns:Major>';
							local.XMLPacket = local.XMLPacket & '<ns:Intermediate>0</ns:Intermediate>';
							local.XMLPacket = local.XMLPacket & '<ns:Minor>0</ns:Minor>';
						local.XMLPacket = local.XMLPacket & '</ns:Version>';
						local.XMLPacket = local.XMLPacket & '<ns:RequestedShipment>';
							local.XMLPacket = local.XMLPacket & '<ns:ShipTimestamp>2018-11-21T08:07:56-06:00</ns:ShipTimestamp>';
							local.XMLPacket = local.XMLPacket & '<ns:DropoffType>REGULAR_PICKUP</ns:DropoffType>';
							local.XMLPacket = local.XMLPacket & '<ns:ServiceType>STANDARD_OVERNIGHT</ns:ServiceType>';
							local.XMLPacket = local.XMLPacket & '<ns:PackagingType>YOUR_PACKAGING</ns:PackagingType>';
							local.XMLPacket = local.XMLPacket & '<ns:Shipper>';
								local.XMLPacket = local.XMLPacket & '<ns:AccountNumber>#variables.accountNo#</ns:AccountNumber>';
								local.XMLPacket = local.XMLPacket & '<ns:Contact>';
									local.XMLPacket = local.XMLPacket & '<ns:PersonName>Name</ns:PersonName>';
									local.XMLPacket = local.XMLPacket & '<ns:CompanyName></ns:CompanyName>';
									local.XMLPacket = local.XMLPacket & '<ns:PhoneNumber>123-456-7890</ns:PhoneNumber>';
									local.XMLPacket = local.XMLPacket & '<ns:EMailAddress>ShipperEmail@ShipperEmail.com</ns:EMailAddress>';
								local.XMLPacket = local.XMLPacket & '</ns:Contact>';
								local.XMLPacket = local.XMLPacket & '<ns:Address>';
									local.XMLPacket = local.XMLPacket & '<ns:StreetLines>111 1st Avenue North</ns:StreetLines>';
									local.XMLPacket = local.XMLPacket & '<ns:City>Minneapolis</ns:City>';
									local.XMLPacket = local.XMLPacket & '<ns:StateOrProvinceCode>MN</ns:StateOrProvinceCode>';
									local.XMLPacket = local.XMLPacket & '<ns:PostalCode>55401</ns:PostalCode>';
									local.XMLPacket = local.XMLPacket & '<ns:CountryCode>US</ns:CountryCode>';
								local.XMLPacket = local.XMLPacket & '</ns:Address>';
							local.XMLPacket = local.XMLPacket & '</ns:Shipper>';
							local.XMLPacket = local.XMLPacket & '<ns:Recipient>';
								local.XMLPacket = local.XMLPacket & '<ns:AccountNumber>#variables.accountNo#</ns:AccountNumber>';
								local.XMLPacket = local.XMLPacket & '<ns:Contact>';
									local.XMLPacket = local.XMLPacket & '<ns:PersonName>NAme</ns:PersonName>';
									local.XMLPacket = local.XMLPacket & '<ns:CompanyName></ns:CompanyName>';
									local.XMLPacket = local.XMLPacket & '<ns:PhoneNumber>123-456-7890</ns:PhoneNumber>';
									local.XMLPacket = local.XMLPacket & '<ns:EMailAddress>Recipient@Recipient.com</ns:EMailAddress>';
								local.XMLPacket = local.XMLPacket & '</ns:Contact>';
								local.XMLPacket = local.XMLPacket & '<ns:Address>';
									local.XMLPacket = local.XMLPacket & '<ns:StreetLines>111 1st Avenue North</ns:StreetLines>';
									local.XMLPacket = local.XMLPacket & '<ns:City>Minneapolis</ns:City>';
									local.XMLPacket = local.XMLPacket & '<ns:StateOrProvinceCode>MN</ns:StateOrProvinceCode>';
									local.XMLPacket = local.XMLPacket & '<ns:PostalCode>55401</ns:PostalCode>';
									local.XMLPacket = local.XMLPacket & '<ns:CountryCode>US</ns:CountryCode>';
								local.XMLPacket = local.XMLPacket & '</ns:Address>';
							local.XMLPacket = local.XMLPacket & '</ns:Recipient>';

							local.XMLPacket = local.XMLPacket & '<ns:ShippingChargesPayment>';
								local.XMLPacket = local.XMLPacket & '<ns:PaymentType>THIRD_PARTY</ns:PaymentType>';
								local.XMLPacket = local.XMLPacket & '<ns:Payor>';
									local.XMLPacket = local.XMLPacket & '<ns:ResponsibleParty>';
											local.XMLPacket = local.XMLPacket & '<ns:AccountNumber>#variables.accountNo#</ns:AccountNumber>';
									local.XMLPacket = local.XMLPacket & '</ns:ResponsibleParty>';
								local.XMLPacket = local.XMLPacket & '</ns:Payor>';
							local.XMLPacket = local.XMLPacket & '</ns:ShippingChargesPayment>';
							local.XMLPacket = local.XMLPacket & '<ns:SpecialServicesRequested>';
								local.XMLPacket = local.XMLPacket & '<ns:SpecialServiceTypes>RETURN_SHIPMENT</ns:SpecialServiceTypes>';
								local.XMLPacket = local.XMLPacket & '<ns:ReturnShipmentDetail>';
									local.XMLPacket = local.XMLPacket & '<ns:ReturnType>PRINT_RETURN_LABEL</ns:ReturnType>';
									local.XMLPacket = local.XMLPacket & '<ns:Rma>';
										local.XMLPacket = local.XMLPacket & '<ns:Reason>Optional Reason</ns:Reason>';
									local.XMLPacket = local.XMLPacket & '</ns:Rma>';
								local.XMLPacket = local.XMLPacket & '</ns:ReturnShipmentDetail>';
							local.XMLPacket = local.XMLPacket & '</ns:SpecialServicesRequested>';
							local.XMLPacket = local.XMLPacket & '<ns:LabelSpecification>';
								local.XMLPacket = local.XMLPacket & '<ns:LabelFormatType>COMMON2D</ns:LabelFormatType>';
								local.XMLPacket = local.XMLPacket & '<ns:ImageType>PNG</ns:ImageType>';
								local.XMLPacket = local.XMLPacket & '<ns:LabelStockType>PAPER_8.5X11_TOP_HALF_LABEL</ns:LabelStockType>';
								local.XMLPacket = local.XMLPacket & '</ns:LabelSpecification>';
							local.XMLPacket = local.XMLPacket & '<ns:ShippingDocumentSpecification>';
								local.XMLPacket = local.XMLPacket & '<ns:ShippingDocumentTypes>RETURN_INSTRUCTIONS</ns:ShippingDocumentTypes>';
								local.XMLPacket = local.XMLPacket & '<ns:ReturnInstructionsDetail>';
									local.XMLPacket = local.XMLPacket & '<ns:Format>';
										local.XMLPacket = local.XMLPacket & '<ns:ImageType>PNG</ns:ImageType>';
										local.XMLPacket = local.XMLPacket & '<ns:StockType>PAPER_LETTER</ns:StockType>';
										local.XMLPacket = local.XMLPacket & '<ns:ProvideInstructions>true</ns:ProvideInstructions>';
									local.XMLPacket = local.XMLPacket & '</ns:Format>';
								local.XMLPacket = local.XMLPacket & '</ns:ReturnInstructionsDetail>';
							local.XMLPacket = local.XMLPacket & '</ns:ShippingDocumentSpecification>';

							local.XMLPacket = local.XMLPacket & '<ns:RateRequestTypes>LIST</ns:RateRequestTypes>';
							local.XMLPacket = local.XMLPacket & '<ns:PackageCount>1</ns:PackageCount>';
							local.XMLPacket = local.XMLPacket & '<ns:RequestedPackageLineItems>';
								local.XMLPacket = local.XMLPacket & '<ns:SequenceNumber>1</ns:SequenceNumber>';
								local.XMLPacket = local.XMLPacket & '<ns:Weight>';
									local.XMLPacket = local.XMLPacket & '<ns:Units>LB</ns:Units>';
									local.XMLPacket = local.XMLPacket & '<ns:Value>40</ns:Value>';
								local.XMLPacket = local.XMLPacket & '</ns:Weight>';
								local.XMLPacket = local.XMLPacket & '<ns:Dimensions>';
									local.XMLPacket = local.XMLPacket & '<ns:Length>5</ns:Length>';
									local.XMLPacket = local.XMLPacket & '<ns:Width>5</ns:Width>';
									local.XMLPacket = local.XMLPacket & '<ns:Height>5</ns:Height>';
									local.XMLPacket = local.XMLPacket & '<ns:Units>IN</ns:Units>';
								local.XMLPacket = local.XMLPacket & '</ns:Dimensions>';
								local.XMLPacket = local.XMLPacket & '<ns:PhysicalPackaging>BOX</ns:PhysicalPackaging>';
								local.XMLPacket = local.XMLPacket & '<ns:ItemDescription>Book</ns:ItemDescription>';
								local.XMLPacket = local.XMLPacket & '<ns:CustomerReferences>';
									local.XMLPacket = local.XMLPacket & '<ns:CustomerReferenceType>CUSTOMER_REFERENCE</ns:CustomerReferenceType>';
									local.XMLPacket = local.XMLPacket & '<ns:Value>NAFTA_COO</ns:Value>';
								local.XMLPacket = local.XMLPacket & '</ns:CustomerReferences>';
							local.XMLPacket = local.XMLPacket & '</ns:RequestedPackageLineItems>';
						local.XMLPacket = local.XMLPacket & '</ns:RequestedShipment>';
					local.XMLPacket = local.XMLPacket & '</ns:ProcessShipmentRequest>';
				local.XMLPacket = local.XMLPacket & '</soapenv:Body>';
			local.XMLPacket = local.XMLPacket & '</soapenv:Envelope>';

			writeOutput("XML POST: ");
			writeDump(local.XMLPacket);

			local.httpService = new http(method="POST", charset="utf-8", url="#variables.fedexurl#/ship");
				httpService.addParam(name="name", type="XML", value="#local.XMLPacket#");
			local.httpResult = local.httpService.send().getPrefix();

			writeOutput('<br><br> httpResult FileContent:');
			writeDump(local.httpResult.FileContent);

			local.xmlFile = XmlParse(local.httpResult.FileContent).Envelope.Body;

			writeOutput('<br><br> RESULTS:');
			cfimage (action="writeToBrowser", source=ToBinary(local.xmlFile.ProcessShipmentReply.CompletedShipmentDetail.CompletedPackageDetails.label.Parts.Image.XmlText));

			return local.result;
		}


		function addressValidation() {
			var local       = {};
			local.result    = {};
			local.XMLPacket = "";

			local.XMLPacket = local.XMLPacket & '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://fedex.com/ws/addressvalidation/v4">';
				local.XMLPacket = local.XMLPacket & '<soapenv:Header/>';
				local.XMLPacket = local.XMLPacket & '<soapenv:Body>';
					local.XMLPacket = local.XMLPacket & '<ns:AddressValidationRequest>';
						local.XMLPacket = local.XMLPacket & '<ns:WebAuthenticationDetail>';
							local.XMLPacket = local.XMLPacket & '<ns:UserCredential>';
								local.XMLPacket = local.XMLPacket & '<ns:Key>#variables.key#</ns:Key>';
								local.XMLPacket = local.XMLPacket & '<ns:Password>#variables.password#</ns:Password>';
							local.XMLPacket = local.XMLPacket & '</ns:UserCredential>';
						local.XMLPacket = local.XMLPacket & '</ns:WebAuthenticationDetail>';
						local.XMLPacket = local.XMLPacket & '<ns:ClientDetail>';
							local.XMLPacket = local.XMLPacket & '<ns:AccountNumber>#variables.accountNo#</ns:AccountNumber>';
							local.XMLPacket = local.XMLPacket & '<ns:MeterNumber>#variables.meterNo#</ns:MeterNumber>';
						local.XMLPacket = local.XMLPacket & '</ns:ClientDetail>'
						local.XMLPacket = local.XMLPacket & '<ns:Version>';
							local.XMLPacket = local.XMLPacket & '<ns:ServiceId>aval</ns:ServiceId>';
							local.XMLPacket = local.XMLPacket & '<ns:Major>4</ns:Major>';
							local.XMLPacket = local.XMLPacket & '<ns:Intermediate>0</ns:Intermediate>';
							local.XMLPacket = local.XMLPacket & '<ns:Minor>0</ns:Minor>';
						local.XMLPacket = local.XMLPacket & '</ns:Version>';
						local.XMLPacket = local.XMLPacket & '<ns:AddressesToValidate>';
							local.XMLPacket = local.XMLPacket & '<ns:ClientReferenceId>#createUUID()#</ns:ClientReferenceId>';
							local.XMLPacket = local.XMLPacket & '<ns:Contact>';
								local.XMLPacket = local.XMLPacket & '<ns:PersonName>Name</ns:PersonName>';
							local.XMLPacket = local.XMLPacket & '</ns:Contact>';
							local.XMLPacket = local.XMLPacket & '<ns:Address>';
								local.XMLPacket = local.XMLPacket & '<ns:StreetLines>350 S 5th St</ns:StreetLines>';
								local.XMLPacket = local.XMLPacket & '<ns:StreetLines>Suite 311</ns:StreetLines>';
								local.XMLPacket = local.XMLPacket & '<ns:City>Minneapolis</ns:City>';
								local.XMLPacket = local.XMLPacket & '<ns:StateOrProvinceCode>MN</ns:StateOrProvinceCode>';
								local.XMLPacket = local.XMLPacket & '<ns:PostalCode>55415</ns:PostalCode>';
								local.XMLPacket = local.XMLPacket & '<ns:CountryCode>USA</ns:CountryCode>';
							local.XMLPacket = local.XMLPacket & '</ns:Address>';
						local.XMLPacket = local.XMLPacket & '</ns:AddressesToValidate>';
					local.XMLPacket = local.XMLPacket & '</ns:AddressValidationRequest>';
				local.XMLPacket = local.XMLPacket & '</soapenv:Body>';
			local.XMLPacket = local.XMLPacket & '</soapenv:Envelope>';

			writeOutput("XML POST: ");
			writeDump(local.XMLPacket);

			local.httpService = new http(method="POST", charset="utf-8", url="#variables.fedexurl#/addressvalidation");
				httpService.addParam(name="name", type="XML", value="#local.XMLPacket#");
			local.httpResult = local.httpService.send().getPrefix();

			writeOutput('<br><br> httpResult FileContent:');
			writeDump(local.httpResult.FileContent);

			local.xmlFile = XmlParse(local.httpResult.FileContent).Envelope.Body;
			writeDump(local.xmlFile);

			if(isDefined("local.xmlFile.Fault")){
				if(isArray(local.xmlFile.Fault.XmlChildren))
					for (local.fault in local.xmlFile.Fault.XmlChildren) {
						if(isArray(local.fault.XmlChildren)){
							for (local.f in local.fault.XmlChildren) {
								if(local.f.XmlName eq 'desc'){
									local.result.message = local.result.message & local.f.XmlText;
								} else if (local.f.XmlName eq 'code'){
									local.result.message = local.result.message & ' ' & local.f.XmlText;
								} else if (local.f.XmlName eq 'cause'){
									local.result.message = local.result.message & ' ' & local.f.XmlText;
								}
							}
							if(len(local.result.message)){
								local.result.message = "<strong>Error:</strong> " & local.result.message;
							}
						}
					}
				}
			}
abort;
			<cfif structKeyExists(local.xmlFile, "AddressValidationReply")>
				<cfif structKeyExists(local.xmlFile.AddressValidationReply, "Notifications")>
					<cfif structKeyExists(local.xmlFile.AddressValidationReply.Notifications, "XmlChildren")>
						<cfif isArray(local.xmlFile.AddressValidationReply.Notifications.XmlChildren)>
							<cfloop array="#local.xmlFile.AddressValidationReply.Notifications.XmlChildren#" index="local.r">
								<cfif isDefined("local.r.XmlName") and local.r.XmlName eq 'HighestSeverity'>
									<cfif local.r.XmlText eq 'SUCCESS'>
										<cfset local.result.success = true>
									</cfif>
								</cfif>
							</cfloop>
						</cfif>
					</cfif>
				</cfif>
				<cfif structKeyExists(local.xmlFile.AddressValidationReply, "AddressResults")>
					<cfif structKeyExists(local.xmlFile.AddressValidationReply.AddressResults, "XmlChildren")>
						<cfif isArray(local.xmlFile.AddressValidationReply.AddressResults.XmlChildren)>
							<cfloop array="#local.xmlFile.AddressValidationReply.AddressResults.XmlChildren#" index="local.s">
								<cfif isDefined("local.s.XmlName") and local.s.XmlName eq 'Classification'>
									<cfset local.result.Classification = local.s.XmlText>
								</cfif>
							</cfloop>
						</cfif>
					</cfif>
				</cfif>
			</cfif>

			writeDump(local.result);

			return local.result;
		}

}


