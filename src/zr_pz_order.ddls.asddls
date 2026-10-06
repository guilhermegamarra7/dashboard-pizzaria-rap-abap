@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Pizzeria - Sales order'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZR_PZ_ORDER
  as select from zpz_order
  composition [0..*] of ZR_PZ_ORDERITEM as _Items
  association [1..1] to ZI_PZ_CHANNEL   as _Channel on $projection.Channel = _Channel.Channel
{
  key order_uuid            as OrderUUID,
      channel               as Channel,
      external_id           as ExternalID,
      order_datetime        as OrderDateTime,
      status                as Status,
      case status
        when 'COMPLETED' then 3
        when 'CANCELLED' then 1
        else 0
      end                   as StatusCriticality,
      cancel_reason         as CancelReason,
      @Semantics.amount.currencyCode: 'Currency'
      items_amount          as ItemsAmount,
      @Semantics.amount.currencyCode: 'Currency'
      delivery_fee          as DeliveryFee,
      @Semantics.amount.currencyCode: 'Currency'
      store_discount        as StoreDiscount,
      @Semantics.amount.currencyCode: 'Currency'
      platform_incentive    as PlatformIncentive,
      @Semantics.amount.currencyCode: 'Currency'
      platform_fees         as PlatformFees,
      @Semantics.amount.currencyCode: 'Currency'
      net_amount            as NetAmount,
      currency              as Currency,
      item_count            as ItemCount,
      payment_method        as PaymentMethod,
      delivery_type         as DeliveryType,
      rating                as Rating,
      customer_comment      as CustomerComment,
      @Semantics.user.createdBy: true
      local_created_by      as LocalCreatedBy,
      @Semantics.systemDateTime.createdAt: true
      local_created_at      as LocalCreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      local_last_changed_by as LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,
      _Items,
      _Channel
}
