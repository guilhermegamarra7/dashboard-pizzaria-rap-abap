@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Pizzeria - Menu margin (dashboard)'
@Metadata.ignorePropagatedAnnotations: true
@UI.headerInfo: { typeName: 'Menu Margin', typeNamePlural: 'Menu Margin by Channel',
                  title: { type: #STANDARD, value: 'ItemName' },
                  description: { type: #STANDARD, value: 'ChannelName' } }
@UI.presentationVariant: [{ sortOrder: [{ by: 'MarginPct', direction: #DESC }],
                            visualizations: [{ type: #AS_LINEITEM }] }]
define view entity ZC_PZ_MENUMARGIN
  as select from ZI_PZ_MENUMARGIN
{
      @UI.facet: [{ id: 'Margin', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'Margin', position: 10 }]
      @UI: { lineItem: [{ position: 10 }], identification: [{ position: 10 }], selectionField: [{ position: 10 }] }
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_PZ_MENUITEM', element: 'MenuItemID' } }]
      @ObjectModel.text.element: ['ItemName']
      @UI.textArrangement: #TEXT_ONLY
      @EndUserText.label: 'Menu Item'
  key MenuItemID,

      @UI: { lineItem: [{ position: 20 }], identification: [{ position: 20 }], selectionField: [{ position: 20 }] }
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_PZ_CHANNEL', element: 'Channel' } }]
      @ObjectModel.text.element: ['ChannelName']
      @UI.textArrangement: #TEXT_ONLY
      @EndUserText.label: 'Channel'
  key Channel,

      @EndUserText.label: 'Item Name'
      ItemName,

      @EndUserText.label: 'Channel Name'
      ChannelName,

      @UI.identification: [{ position: 30 }]
      @EndUserText.label: 'Platform Fee (%)'
      PlatformFeePct,

      @UI: { lineItem: [{ position: 30 }], identification: [{ position: 40 }] }
      @Semantics.amount.currencyCode: 'Currency'
      @EndUserText.label: 'Price'
      cast( Price as abap.curr(11,2) )       as Price,

      @UI: { lineItem: [{ position: 40 }], identification: [{ position: 50 }] }
      @Semantics.amount.currencyCode: 'Currency'
      @EndUserText.label: 'Platform Fee'
      cast( PlatformFee as abap.curr(11,2) ) as PlatformFee,

      @UI: { lineItem: [{ position: 50 }], identification: [{ position: 60 }] }
      @Semantics.amount.currencyCode: 'Currency'
      @EndUserText.label: 'Recipe Cost'
      cast( RecipeCost as abap.curr(11,2) )  as RecipeCost,

      @UI: { lineItem: [{ position: 60 }], identification: [{ position: 70 }] }
      @Semantics.amount.currencyCode: 'Currency'
      @EndUserText.label: 'Margin'
      cast( Margin as abap.curr(11,2) )      as Margin,

      @UI: { lineItem: [{ position: 70, criticality: 'MarginCriticality' }],
             identification: [{ position: 80, criticality: 'MarginCriticality' }] }
      @EndUserText.label: 'Margin (%)'
      MarginPct,

      @UI.hidden: true
      case when MarginPct >= 50 then 3
           when MarginPct >= 35 then 2
           else 1
      end                                    as MarginCriticality,

      @EndUserText.label: 'Currency'
      Currency
}
