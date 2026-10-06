@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Pizzeria - Monthly revenue by channel'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_PZ_MONTHLYREVENUE
  as select from ZI_PZ_ORDERFACT
{
  key YearMonth,
  key Channel,
      sum( case Status when 'COMPLETED' then 1 else 0 end )          as CompletedOrders,
      sum( case Status when 'CANCELLED' then 1 else 0 end )          as CancelledOrders,
      @Semantics.amount.currencyCode: 'Currency'
      sum( case Status when 'COMPLETED' then ItemsAmount end )       as GrossRevenue,
      @Semantics.amount.currencyCode: 'Currency'
      sum( case Status when 'COMPLETED' then StoreDiscount end )     as StoreDiscounts,
      @Semantics.amount.currencyCode: 'Currency'
      sum( PlatformFees )                                            as PlatformFees,
      @Semantics.amount.currencyCode: 'Currency'
      sum( NetAmount )                                               as NetRevenue,
      @Semantics.amount.currencyCode: 'Currency'
      sum( case Status when 'CANCELLED' then ItemsAmount end )       as LostToCancellations,
      Currency
}
group by
  YearMonth,
  Channel,
  Currency
