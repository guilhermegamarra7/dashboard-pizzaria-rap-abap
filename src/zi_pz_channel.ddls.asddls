@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Pizzeria - Sales channel'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_PZ_CHANNEL
  as select from zpz_channel
{
      @ObjectModel.text.element: ['ChannelName']
      @EndUserText.label: 'Channel'
  key channel          as Channel,
      @Semantics.text: true
      @EndUserText.label: 'Channel Name'
      channel_name     as ChannelName,
      @EndUserText.label: 'Sales Channel'
      is_sales_channel as IsSalesChannel,
      @EndUserText.label: 'Platform Fee (%)'
      platform_fee_pct as PlatformFeePct
}
