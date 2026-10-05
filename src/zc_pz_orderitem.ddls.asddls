@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Pizzeria - Sales order item (projection)'
@UI.headerInfo: { typeName: 'Item', typeNamePlural: 'Items',
                  title: { type: #STANDARD, value: 'MenuItemID' } }
define view entity ZC_PZ_ORDERITEM
  as projection on ZR_PZ_ORDERITEM
{
      @UI.facet: [ { id: 'Item', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'Item', position: 10 } ]
      @UI.hidden: true
  key ItemUUID,

      @UI.hidden: true
      OrderUUID,

      @UI: { lineItem: [{ position: 10 }], identification: [{ position: 10 }] }
      @EndUserText.label: 'Menu Item'
      MenuItemID,

      @UI: { lineItem: [{ position: 20 }], identification: [{ position: 20 }] }
      @EndUserText.label: 'Quantity'
      Quantity,

      @UI: { lineItem: [{ position: 30 }], identification: [{ position: 30 }] }
      @EndUserText.label: 'Total Amount'
      @Semantics.amount.currencyCode: 'Currency'
      TotalAmount,

      @EndUserText.label: 'Currency'
      Currency,

      LocalLastChangedAt,

      _Order : redirected to parent ZC_PZ_ORDER
}
