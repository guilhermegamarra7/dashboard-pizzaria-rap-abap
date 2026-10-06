@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Pizzeria - Monthly revenue (dashboard)'
@Metadata.ignorePropagatedAnnotations: true
@UI.headerInfo: { typeName: 'Monthly Revenue', typeNamePlural: 'Monthly Revenue by Channel',
                  title: { type: #STANDARD, value: 'YearMonth' },
                  description: { type: #STANDARD, value: 'ChannelName' } }
@UI.presentationVariant: [{ sortOrder: [{ by: 'YearMonth', direction: #DESC }, { by: 'NetRevenue', direction: #DESC }],
                            visualizations: [{ type: #AS_LINEITEM }] }]
define view entity ZC_PZ_MONTHLYREVENUE
  as select from ZI_PZ_MONTHLYREVENUE
  association [1..1] to ZI_PZ_CHANNEL as _Channel on $projection.Channel = _Channel.Channel
{
      @UI.facet: [{ id: 'Revenue', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'Revenue', position: 10 }]
      @UI: { lineItem: [{ position: 10 }], identification: [{ position: 10 }], selectionField: [{ position: 10 }] }
      @EndUserText.label: 'Month'
  key YearMonth,

      @UI: { lineItem: [{ position: 20 }], identification: [{ position: 20 }], selectionField: [{ position: 20 }] }
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_PZ_CHANNEL', element: 'Channel' } }]
      @ObjectModel.text.element: ['ChannelName']
      @UI.textArrangement: #TEXT_ONLY
      @EndUserText.label: 'Channel'
  key Channel,

      @EndUserText.label: 'Channel Name'
      _Channel.ChannelName as ChannelName,

      @UI: { lineItem: [{ position: 30 }], identification: [{ position: 30 }] }
      @EndUserText.label: 'Orders'
      CompletedOrders,

      @UI: { lineItem: [{ position: 40 }], identification: [{ position: 40 }] }
      @EndUserText.label: 'Cancelled'
      CancelledOrders,

      @UI: { lineItem: [{ position: 50 }], identification: [{ position: 50 }] }
      @Semantics.amount.currencyCode: 'Currency'
      @EndUserText.label: 'Gross Revenue'
      GrossRevenue,

      @UI.identification: [{ position: 60 }]
      @Semantics.amount.currencyCode: 'Currency'
      @EndUserText.label: 'Store Discounts'
      StoreDiscounts,

      @UI: { lineItem: [{ position: 60 }], identification: [{ position: 70 }] }
      @Semantics.amount.currencyCode: 'Currency'
      @EndUserText.label: 'Platform Fees'
      PlatformFees,

      @UI: { lineItem: [{ position: 70 }], identification: [{ position: 80 }] }
      @Semantics.amount.currencyCode: 'Currency'
      @EndUserText.label: 'Net Revenue'
      NetRevenue,

      @UI: { lineItem: [{ position: 80 }], identification: [{ position: 90 }] }
      @Semantics.amount.currencyCode: 'Currency'
      @EndUserText.label: 'Average Ticket'
      case when CompletedOrders > 0
           then cast( division( cast( GrossRevenue as abap.dec(13,2) ), CompletedOrders, 2 ) as abap.curr(13,2) )
      end as AverageTicket,

      @UI: { lineItem: [{ position: 90 }], identification: [{ position: 100 }] }
      @Semantics.amount.currencyCode: 'Currency'
      @EndUserText.label: 'Lost to Cancellations'
      LostToCancellations,

      @EndUserText.label: 'Currency'
      Currency
}
