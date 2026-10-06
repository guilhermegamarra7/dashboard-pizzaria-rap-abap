@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Pizzeria - Recipe cost per menu item'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_PZ_MENUITEMCOST
  as select from zpz_recipe
{
  key menu_item_id as MenuItemID,
      @Semantics.amount.currencyCode: 'Currency'
      sum( cost )  as RecipeCost,
      currency     as Currency
}
group by
  menu_item_id,
  currency
