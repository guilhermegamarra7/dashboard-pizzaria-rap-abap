@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Pizzeria - Sales order facts'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_PZ_ORDERFACT
  as select from zpz_order
{
  key order_uuid         as OrderUUID,
      channel            as Channel,
      status             as Status,

      // Orders are stored in UTC; the pizzeria works in Brasilia time
      tstmp_to_dats( cast( order_datetime as abap.dec(15,0) ), 'BRAZIL', $session.client, 'NULL' ) as OrderDate,

      // YYYY-MM of the local order date
      concat( concat( left( cast( tstmp_to_dats( cast( order_datetime as abap.dec(15,0) ),
                                                 'BRAZIL', $session.client, 'NULL' ) as abap.char(8) ), 4 ), '-' ),
              substring( cast( tstmp_to_dats( cast( order_datetime as abap.dec(15,0) ),
                                              'BRAZIL', $session.client, 'NULL' ) as abap.char(8) ), 5, 2 ) ) as YearMonth,

      @Semantics.amount.currencyCode: 'Currency'
      items_amount       as ItemsAmount,
      @Semantics.amount.currencyCode: 'Currency'
      store_discount     as StoreDiscount,
      @Semantics.amount.currencyCode: 'Currency'
      platform_fees      as PlatformFees,
      @Semantics.amount.currencyCode: 'Currency'
      net_amount         as NetAmount,
      currency           as Currency
}
