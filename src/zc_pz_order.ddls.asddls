@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Pizzeria - Sales order (projection)'
@UI.headerInfo: { typeName: 'Sales Order', typeNamePlural: 'Sales Orders',
                  title: { type: #STANDARD, value: 'Channel' },
                  description: { type: #STANDARD, value: 'ExternalID' } }
define root view entity ZC_PZ_ORDER
  provider contract transactional_query
  as projection on ZR_PZ_ORDER
{
      @UI.facet: [ { id: 'SalesOrder', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'Sales Order', position: 10 },
                   { id: 'Items',      purpose: #STANDARD, type: #LINEITEM_REFERENCE,       label: 'Items',       position: 20, targetElement: '_Items' } ]
      @UI.hidden: true
  key OrderUUID,

      @UI: { lineItem: [{ position: 10 }], identification: [{ position: 10 }], selectionField: [{ position: 10 }] }
      @EndUserText.label: 'Channel'
      Channel,

      @UI: { lineItem: [{ position: 20 }], identification: [{ position: 20 }] }
      @EndUserText.label: 'Order Date/Time'
      OrderDateTime,

      @UI: { lineItem: [{ position: 30 }], identification: [{ position: 30 }], selectionField: [{ position: 20 }] }
      @EndUserText.label: 'Status'
      Status,

      @UI.identification: [{ position: 40 }]
      @EndUserText.label: 'Cancellation Reason'
      CancelReason,

      @UI.identification: [{ position: 50 }]
      @EndUserText.label: 'External ID'
      ExternalID,

      @UI: { lineItem: [{ position: 40 }], identification: [{ position: 60 }] }
      @EndUserText.label: 'Items Amount'
      @Semantics.amount.currencyCode: 'Currency'
      ItemsAmount,

      @UI.identification: [{ position: 70 }]
      @EndUserText.label: 'Delivery Fee'
      @Semantics.amount.currencyCode: 'Currency'
      DeliveryFee,

      @UI.identification: [{ position: 80 }]
      @EndUserText.label: 'Store Discount'
      @Semantics.amount.currencyCode: 'Currency'
      StoreDiscount,

      @UI.identification: [{ position: 90 }]
      @EndUserText.label: 'Platform Incentive'
      @Semantics.amount.currencyCode: 'Currency'
      PlatformIncentive,

      @UI.identification: [{ position: 100 }]
      @EndUserText.label: 'Platform Fees'
      @Semantics.amount.currencyCode: 'Currency'
      PlatformFees,

      @UI: { lineItem: [{ position: 50 }], identification: [{ position: 110 }] }
      @EndUserText.label: 'Net Amount'
      @Semantics.amount.currencyCode: 'Currency'
      NetAmount,

      @EndUserText.label: 'Currency'
      Currency,

      @UI: { lineItem: [{ position: 60 }], identification: [{ position: 120 }] }
      @EndUserText.label: 'Payment Method'
      PaymentMethod,

      @UI.identification: [{ position: 130 }]
      @EndUserText.label: 'Delivery Type'
      DeliveryType,

      @UI.identification: [{ position: 140 }]
      @EndUserText.label: 'Item Count'
      ItemCount,

      @UI.identification: [{ position: 150 }]
      @EndUserText.label: 'Rating'
      Rating,

      @UI.identification: [{ position: 160 }]
      @EndUserText.label: 'Customer Comment'
      CustomerComment,

      LocalCreatedBy,
      LocalCreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,

      _Items : redirected to composition child ZC_PZ_ORDERITEM
}   
