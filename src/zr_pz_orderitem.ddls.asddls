@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Pizzeria - Sales order item'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZR_PZ_ORDERITEM
  as select from zpz_order_item
  association to parent ZR_PZ_ORDER as _Order    on $projection.OrderUUID = _Order.OrderUUID
  association [1..1] to ZI_PZ_MENUITEM  as _MenuItem on $projection.MenuItemID = _MenuItem.MenuItemID
{
  key item_uuid             as ItemUUID,
      order_uuid            as OrderUUID,
      menu_item_id          as MenuItemID,
      quantity              as Quantity,
      @Semantics.amount.currencyCode: 'Currency'
      total_amount          as TotalAmount,
      currency              as Currency,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      _Order,
      _MenuItem
}
