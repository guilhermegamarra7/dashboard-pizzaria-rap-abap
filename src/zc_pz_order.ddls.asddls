@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Pizzeria - Sales order (projection)'
@UI.headerInfo: { typeName: 'Sales Order', typeNamePlural: 'Sales Orders',
                  title: { type: #STANDARD, value: 'ChannelName' },
                  description: { type: #STANDARD, value: 'ExternalID' } }
@UI.presentationVariant: [{ sortOrder: [{ by: 'OrderDateTime', direction: #DESC }],
                            visualizations: [{ type: #AS_LINEITEM }] }]
define root view entity ZC_PZ_ORDER
  provider contract transactional_query
  as projection on ZR_PZ_ORDER
{
      @UI.facet: [ { id: 'HeaderStatus',    purpose: #HEADER,   type: #DATAPOINT_REFERENCE, targetQualifier: 'Status',    position: 10 },
                   { id: 'HeaderNetAmount', purpose: #HEADER,   type: #DATAPOINT_REFERENCE, targetQualifier: 'NetAmount', position: 20 },
                   { id: 'General',         purpose: #STANDARD, type: #COLLECTION,          label: 'Sales Order',        position: 10 },
                   { id: 'Order',     parentId: 'General', type: #FIELDGROUP_REFERENCE, targetQualifier: 'Order',    label: 'Order',             position: 10 },
                   { id: 'Amounts',   parentId: 'General', type: #FIELDGROUP_REFERENCE, targetQualifier: 'Amounts',  label: 'Amounts',           position: 20 },
                   { id: 'Feedback',  parentId: 'General', type: #FIELDGROUP_REFERENCE, targetQualifier: 'Feedback', label: 'Customer Feedback', position: 30 },
                   { id: 'Items',           purpose: #STANDARD, type: #LINEITEM_REFERENCE,  label: 'Items',              position: 20, targetElement: '_Items' } ]
      @UI.hidden: true
  key OrderUUID,

      @UI: { lineItem: [{ position: 10 }], selectionField: [{ position: 10 }],
             fieldGroup: [{ qualifier: 'Order', position: 10 }] }
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_PZ_CHANNEL', element: 'Channel' }, useForValidation: true }]
      @ObjectModel.text.element: ['ChannelName']
      @UI.textArrangement: #TEXT_ONLY
      @EndUserText.label: 'Channel'
      Channel,

      @EndUserText.label: 'Channel Name'
      _Channel.ChannelName as ChannelName,

      @UI: { lineItem: [{ position: 20 }], selectionField: [{ position: 30 }],
             fieldGroup: [{ qualifier: 'Order', position: 20 }] }
      @EndUserText.label: 'Order Date/Time'
      OrderDateTime,

      @UI: { lineItem:       [{ position: 30, criticality: 'StatusCriticality' },
                              { type: #FOR_ACTION, dataAction: 'cancelOrder', label: 'Cancel Order' }],
             identification: [{ type: #FOR_ACTION, dataAction: 'cancelOrder', label: 'Cancel Order' }],
             selectionField: [{ position: 20 }],
             fieldGroup:     [{ qualifier: 'Order', position: 30, criticality: 'StatusCriticality' }],
             dataPoint:      { qualifier: 'Status', title: 'Status', criticality: 'StatusCriticality' } }
      @EndUserText.label: 'Status'
      Status,

      @UI.hidden: true
      StatusCriticality,

      @UI.fieldGroup: [{ qualifier: 'Order', position: 40 }]
      @EndUserText.label: 'Cancellation Reason'
      CancelReason,

      @UI.fieldGroup: [{ qualifier: 'Order', position: 50 }]
      @EndUserText.label: 'External ID'
      ExternalID,

      @UI: { lineItem: [{ position: 40 }], fieldGroup: [{ qualifier: 'Amounts', position: 10 }] }
      @EndUserText.label: 'Items Amount'
      @Semantics.amount.currencyCode: 'Currency'
      ItemsAmount,

      @UI.fieldGroup: [{ qualifier: 'Amounts', position: 20 }]
      @EndUserText.label: 'Delivery Fee'
      @Semantics.amount.currencyCode: 'Currency'
      DeliveryFee,

      @UI.fieldGroup: [{ qualifier: 'Amounts', position: 30 }]
      @EndUserText.label: 'Store Discount'
      @Semantics.amount.currencyCode: 'Currency'
      StoreDiscount,

      @UI.fieldGroup: [{ qualifier: 'Amounts', position: 40 }]
      @EndUserText.label: 'Platform Incentive'
      @Semantics.amount.currencyCode: 'Currency'
      PlatformIncentive,

      @UI.fieldGroup: [{ qualifier: 'Amounts', position: 50 }]
      @EndUserText.label: 'Platform Fees'
      @Semantics.amount.currencyCode: 'Currency'
      PlatformFees,

      @UI: { lineItem: [{ position: 50 }], fieldGroup: [{ qualifier: 'Amounts', position: 60 }],
             dataPoint: { qualifier: 'NetAmount', title: 'Net Amount' } }
      @EndUserText.label: 'Net Amount'
      @Semantics.amount.currencyCode: 'Currency'
      NetAmount,

      @EndUserText.label: 'Currency'
      Currency,

      @UI: { lineItem: [{ position: 60 }], selectionField: [{ position: 40 }],
             fieldGroup: [{ qualifier: 'Order', position: 60 }] }
      @EndUserText.label: 'Payment Method'
      PaymentMethod,

      @UI.fieldGroup: [{ qualifier: 'Order', position: 70 }]
      @EndUserText.label: 'Delivery Type'
      DeliveryType,

      @UI.fieldGroup: [{ qualifier: 'Amounts', position: 70 }]
      @EndUserText.label: 'Item Count'
      ItemCount,

      @UI: { fieldGroup: [{ qualifier: 'Feedback', position: 10, type: #AS_DATAPOINT }],
             dataPoint: { visualization: #RATING, targetValue: 5 } }
      @EndUserText.label: 'Rating'
      Rating,

      @UI.fieldGroup: [{ qualifier: 'Feedback', position: 20 }]
      @EndUserText.label: 'Customer Comment'
      CustomerComment,

      LocalCreatedBy,
      LocalCreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,

      _Items : redirected to composition child ZC_PZ_ORDERITEM
}
