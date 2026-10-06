@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Pizzeria - Menu margin per channel'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_PZ_MENUMARGIN
  as select from ZI_PZ_MENUITEM     as Item
    inner join   ZI_PZ_MENUITEMCOST as Cost on Cost.MenuItemID = Item.MenuItemID
    cross join   ZI_PZ_CHANNEL      as Channel
{
  key Item.MenuItemID,
  key Channel.Channel,
      Item.ItemName,
      Item.ItemType,
      Channel.ChannelName,
      Channel.PlatformFeePct,

      // Margin = price - platform fee - recipe cost
      cast( Item.Price as abap.dec(11,2) )                                              as Price,
      division( cast( Item.Price as abap.dec(11,2) ) * Channel.PlatformFeePct, 100, 2 ) as PlatformFee,
      cast( Cost.RecipeCost as abap.dec(11,2) )                                         as RecipeCost,
      cast( Item.Price as abap.dec(11,2) )
        - division( cast( Item.Price as abap.dec(11,2) ) * Channel.PlatformFeePct, 100, 2 )
        - cast( Cost.RecipeCost as abap.dec(11,2) )                                     as Margin,
      division( ( cast( Item.Price as abap.dec(11,2) )
                  - division( cast( Item.Price as abap.dec(11,2) ) * Channel.PlatformFeePct, 100, 2 )
                  - cast( Cost.RecipeCost as abap.dec(11,2) ) ) * 100,
                cast( Item.Price as abap.dec(11,2) ), 1 )                               as MarginPct,
      Item.Currency
}
where
      Item.IsActive          = 'X'
  and Channel.IsSalesChannel = 'X'
