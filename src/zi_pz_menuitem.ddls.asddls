@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Pizzeria - Menu item'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_PZ_MENUITEM
  as select from zpz_menu_item
{
      @ObjectModel.text.element: ['ItemName']
      @EndUserText.label: 'Menu Item'
  key menu_item_id as MenuItemID,
      @Semantics.text: true
      @EndUserText.label: 'Item Name'
      item_name    as ItemName,
      @EndUserText.label: 'Item Type'
      item_type    as ItemType,
      @Semantics.amount.currencyCode: 'Currency'
      @EndUserText.label: 'Price'
      price        as Price,
      currency     as Currency,
      @EndUserText.label: 'Active'
      is_active    as IsActive
}
