CLASS lhc_salesorder DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    CONSTANTS:
      BEGIN OF status,
        completed TYPE zpz_order-status VALUE 'COMPLETED',
        cancelled TYPE zpz_order-status VALUE 'CANCELLED',
      END OF status.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR SalesOrder RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR SalesOrder RESULT result.

    METHODS cancelOrder FOR MODIFY
      IMPORTING keys FOR ACTION SalesOrder~cancelOrder RESULT result.

    METHODS recalculateAmounts FOR MODIFY
      IMPORTING keys FOR ACTION SalesOrder~recalculateAmounts.

    METHODS setDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR SalesOrder~setDefaults.

    METHODS calculateAmounts FOR DETERMINE ON MODIFY
      IMPORTING keys FOR SalesOrder~calculateAmounts.

    METHODS validateChannel FOR VALIDATE ON SAVE
      IMPORTING keys FOR SalesOrder~validateChannel.
ENDCLASS.


CLASS lhc_salesorder IMPLEMENTATION.

  METHOD get_global_authorizations.
    " Everybody who can open the app may create, change and cancel orders.
    " A real system would check an authorization object here.
  ENDMETHOD.


  METHOD get_instance_features.
    READ ENTITIES OF zr_pz_order IN LOCAL MODE
      ENTITY SalesOrder
        FIELDS ( Status ) WITH CORRESPONDING #( keys )
      RESULT DATA(orders)
      FAILED failed.

    result = VALUE #( FOR order IN orders
                      ( %tky                = order-%tky
                        %action-cancelOrder = COND #( WHEN order-Status = status-cancelled
                                                      THEN if_abap_behv=>fc-o-disabled
                                                      ELSE if_abap_behv=>fc-o-enabled ) ) ).
  ENDMETHOD.


  METHOD cancelOrder.
    LOOP AT keys INTO DATA(key) WHERE %param-CancelReason IS INITIAL.
      APPEND VALUE #( %tky = key-%tky ) TO failed-salesorder.
      APPEND VALUE #( %tky = key-%tky
                      %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                    text     = 'Enter a cancellation reason' ) )
             TO reported-salesorder.
    ENDLOOP.

    " A cancelled order earns nothing and pays no platform fee
    MODIFY ENTITIES OF zr_pz_order IN LOCAL MODE
      ENTITY SalesOrder
        UPDATE FIELDS ( Status CancelReason PlatformFees NetAmount )
        WITH VALUE #( FOR k IN keys WHERE ( %param-CancelReason IS NOT INITIAL )
                      ( %tky         = k-%tky
                        Status       = status-cancelled
                        CancelReason = k-%param-CancelReason
                        PlatformFees = 0
                        NetAmount    = 0 ) ).

    READ ENTITIES OF zr_pz_order IN LOCAL MODE
      ENTITY SalesOrder
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(orders).

    result = VALUE #( FOR order IN orders ( %tky = order-%tky %param = order ) ).
  ENDMETHOD.


  METHOD recalculateAmounts.
    DATA fee_pct TYPE zpz_channel-platform_fee_pct.

    READ ENTITIES OF zr_pz_order IN LOCAL MODE
      ENTITY SalesOrder
        FIELDS ( Channel Status StoreDiscount ) WITH CORRESPONDING #( keys )
        RESULT DATA(orders)
      ENTITY SalesOrder BY \_Items
        FIELDS ( OrderUUID Quantity TotalAmount ) WITH CORRESPONDING #( keys )
        RESULT DATA(items).

    IF orders IS INITIAL.
      RETURN.
    ENDIF.

    SELECT FROM zi_pz_channel WITH PRIVILEGED ACCESS
      FIELDS Channel, PlatformFeePct
      FOR ALL ENTRIES IN @orders
      WHERE Channel = @orders-Channel
      INTO TABLE @DATA(channels).

    LOOP AT orders ASSIGNING FIELD-SYMBOL(<order>).
      <order>-ItemsAmount = 0.
      <order>-ItemCount   = 0.
      LOOP AT items INTO DATA(item) WHERE OrderUUID = <order>-OrderUUID.
        <order>-ItemsAmount += item-TotalAmount.
        <order>-ItemCount   += item-Quantity.
      ENDLOOP.

      IF <order>-Status = status-cancelled.
        <order>-PlatformFees = 0.
        <order>-NetAmount    = 0.
      ELSE.
        " The platform fee is estimated from the channel. Imported orders keep the
        " fee from the platform report until they are changed in the app.
        fee_pct = VALUE #( channels[ Channel = <order>-Channel ]-PlatformFeePct OPTIONAL ).
        <order>-PlatformFees = <order>-ItemsAmount * fee_pct / 100.
        <order>-NetAmount    = <order>-ItemsAmount - <order>-StoreDiscount - <order>-PlatformFees.
      ENDIF.
    ENDLOOP.

    MODIFY ENTITIES OF zr_pz_order IN LOCAL MODE
      ENTITY SalesOrder
        UPDATE FIELDS ( ItemsAmount ItemCount PlatformFees NetAmount )
        WITH CORRESPONDING #( orders ).
  ENDMETHOD.


  METHOD setDefaults.
    DATA now TYPE timestampl.
    GET TIME STAMP FIELD now.

    READ ENTITIES OF zr_pz_order IN LOCAL MODE
      ENTITY SalesOrder
        FIELDS ( Status OrderDateTime DeliveryType ) WITH CORRESPONDING #( keys )
      RESULT DATA(orders).

    MODIFY ENTITIES OF zr_pz_order IN LOCAL MODE
      ENTITY SalesOrder
        UPDATE FIELDS ( Status OrderDateTime DeliveryType Currency )
        WITH VALUE #( FOR order IN orders
                      ( %tky          = order-%tky
                        Status        = COND #( WHEN order-Status IS INITIAL
                                                THEN status-completed ELSE order-Status )
                        OrderDateTime = COND #( WHEN order-OrderDateTime IS INITIAL
                                                THEN now ELSE order-OrderDateTime )
                        DeliveryType  = COND #( WHEN order-DeliveryType IS INITIAL
                                                THEN 'DELIVERY' ELSE order-DeliveryType )
                        Currency      = 'BRL' ) ).
  ENDMETHOD.


  METHOD calculateAmounts.
    MODIFY ENTITIES OF zr_pz_order IN LOCAL MODE
      ENTITY SalesOrder
        EXECUTE recalculateAmounts FROM CORRESPONDING #( keys ).
  ENDMETHOD.


  METHOD validateChannel.
    READ ENTITIES OF zr_pz_order IN LOCAL MODE
      ENTITY SalesOrder
        FIELDS ( Channel ) WITH CORRESPONDING #( keys )
      RESULT DATA(orders).

    IF orders IS INITIAL.
      RETURN.
    ENDIF.

    " Master data lookup. Validations run while saving, where no authorization check is allowed.
    SELECT FROM zi_pz_channel WITH PRIVILEGED ACCESS
      FIELDS Channel
      FOR ALL ENTRIES IN @orders
      WHERE Channel = @orders-Channel
      INTO TABLE @DATA(channels).

    LOOP AT orders INTO DATA(order).
      " Clear the message of the previous check
      APPEND VALUE #( %tky = order-%tky %state_area = 'VALIDATE_CHANNEL' ) TO reported-salesorder.

      IF order-Channel IS INITIAL OR NOT line_exists( channels[ Channel = order-Channel ] ).
        APPEND VALUE #( %tky = order-%tky ) TO failed-salesorder.
        APPEND VALUE #( %tky             = order-%tky
                        %state_area      = 'VALIDATE_CHANNEL'
                        %msg             = new_message_with_text(
                                             severity = if_abap_behv_message=>severity-error
                                             text     = COND #( WHEN order-Channel IS INITIAL
                                                                THEN `Select a sales channel`
                                                                ELSE |Channel { order-Channel } does not exist| ) )
                        %element-Channel = if_abap_behv=>mk-on ) TO reported-salesorder.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.


CLASS lhc_salesorderitem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setItemDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR SalesOrderItem~setItemDefaults.

    METHODS calculateItemAmount FOR DETERMINE ON MODIFY
      IMPORTING keys FOR SalesOrderItem~calculateItemAmount.

    METHODS validateMenuItem FOR VALIDATE ON SAVE
      IMPORTING keys FOR SalesOrderItem~validateMenuItem.

    METHODS validateQuantity FOR VALIDATE ON SAVE
      IMPORTING keys FOR SalesOrderItem~validateQuantity.
ENDCLASS.


CLASS lhc_salesorderitem IMPLEMENTATION.

  METHOD setItemDefaults.
    READ ENTITIES OF zr_pz_order IN LOCAL MODE
      ENTITY SalesOrderItem
        FIELDS ( Quantity ) WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    MODIFY ENTITIES OF zr_pz_order IN LOCAL MODE
      ENTITY SalesOrderItem
        UPDATE FIELDS ( Quantity )
        WITH VALUE #( FOR item IN items WHERE ( Quantity IS INITIAL )
                      ( %tky = item-%tky Quantity = 1 ) ).
  ENDMETHOD.


  METHOD calculateItemAmount.
    DATA items_to_update TYPE TABLE FOR UPDATE zr_pz_order\\SalesOrderItem.
    DATA order_keys TYPE TABLE FOR ACTION IMPORT zr_pz_order\\SalesOrder~recalculateAmounts.
    DATA order_uuid TYPE sysuuid_x16.

    READ ENTITIES OF zr_pz_order IN LOCAL MODE
      ENTITY SalesOrderItem
        FIELDS ( OrderUUID MenuItemID Quantity ) WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    " Item amount = menu price x quantity
    IF items IS NOT INITIAL.
      SELECT FROM zi_pz_menuitem WITH PRIVILEGED ACCESS
        FIELDS MenuItemID, Price, Currency
        FOR ALL ENTRIES IN @items
        WHERE MenuItemID = @items-MenuItemID
        INTO TABLE @DATA(menu_items).

      LOOP AT items INTO DATA(item).
        ASSIGN menu_items[ MenuItemID = item-MenuItemID ] TO FIELD-SYMBOL(<menu_item>).
        IF sy-subrc <> 0.
          CONTINUE. " validateMenuItem reports it on save
        ENDIF.
        APPEND VALUE #( %tky        = item-%tky
                        TotalAmount = <menu_item>-Price * item-Quantity
                        Currency    = <menu_item>-Currency ) TO items_to_update.
      ENDLOOP.

      MODIFY ENTITIES OF zr_pz_order IN LOCAL MODE
        ENTITY SalesOrderItem
          UPDATE FIELDS ( TotalAmount Currency ) WITH items_to_update.
    ENDIF.

    " Recalculate the orders of new, changed and deleted items. A deleted item can no
    " longer be read through the business object, so its order comes from the table that
    " still holds it: the draft table for a draft, the database table otherwise.
    order_keys = VALUE #( FOR i IN items ( %is_draft = i-%is_draft OrderUUID = i-OrderUUID ) ).
    LOOP AT keys INTO DATA(key).
      IF line_exists( items[ %is_draft = key-%is_draft ItemUUID = key-ItemUUID ] ).
        CONTINUE.
      ENDIF.
      CLEAR order_uuid.
      IF key-%is_draft = if_abap_behv=>mk-on.
        SELECT SINGLE FROM zpz_order_item_d
          FIELDS orderuuid
          WHERE itemuuid = @key-ItemUUID
          INTO @order_uuid.
      ELSE.
        SELECT SINGLE FROM zpz_order_item
          FIELDS order_uuid
          WHERE item_uuid = @key-ItemUUID
          INTO @order_uuid.
      ENDIF.
      IF order_uuid IS NOT INITIAL.
        APPEND VALUE #( %is_draft = key-%is_draft OrderUUID = order_uuid ) TO order_keys.
      ENDIF.
    ENDLOOP.

    SORT order_keys BY %is_draft OrderUUID.
    DELETE ADJACENT DUPLICATES FROM order_keys COMPARING %is_draft OrderUUID.

    MODIFY ENTITIES OF zr_pz_order IN LOCAL MODE
      ENTITY SalesOrder
        EXECUTE recalculateAmounts FROM order_keys.
  ENDMETHOD.


  METHOD validateMenuItem.
    READ ENTITIES OF zr_pz_order IN LOCAL MODE
      ENTITY SalesOrderItem
        FIELDS ( OrderUUID MenuItemID ) WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    IF items IS INITIAL.
      RETURN.
    ENDIF.

    SELECT FROM zi_pz_menuitem WITH PRIVILEGED ACCESS
      FIELDS MenuItemID
      FOR ALL ENTRIES IN @items
      WHERE MenuItemID = @items-MenuItemID
      INTO TABLE @DATA(menu_items).

    LOOP AT items INTO DATA(item).
      " Clear the message of the previous check
      APPEND VALUE #( %tky = item-%tky %state_area = 'VALIDATE_MENU_ITEM' ) TO reported-salesorderitem.

      IF NOT line_exists( menu_items[ MenuItemID = item-MenuItemID ] ).
        APPEND VALUE #( %tky = item-%tky ) TO failed-salesorderitem.
        APPEND VALUE #( %tky                = item-%tky
                        %state_area         = 'VALIDATE_MENU_ITEM'
                        %path               = VALUE #( SalesOrder-%is_draft = item-%is_draft
                                                       SalesOrder-OrderUUID = item-OrderUUID )
                        %msg                = new_message_with_text(
                                                severity = if_abap_behv_message=>severity-error
                                                text     = COND #( WHEN item-MenuItemID IS INITIAL
                                                                   THEN `Select a menu item`
                                                                   ELSE |Menu item { item-MenuItemID } does not exist| ) )
                        %element-MenuItemID = if_abap_behv=>mk-on ) TO reported-salesorderitem.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD validateQuantity.
    READ ENTITIES OF zr_pz_order IN LOCAL MODE
      ENTITY SalesOrderItem
        FIELDS ( OrderUUID Quantity ) WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    LOOP AT items INTO DATA(item).
      " Clear the message of the previous check
      APPEND VALUE #( %tky = item-%tky %state_area = 'VALIDATE_QUANTITY' ) TO reported-salesorderitem.

      IF item-Quantity <= 0.
        APPEND VALUE #( %tky = item-%tky ) TO failed-salesorderitem.
        APPEND VALUE #( %tky              = item-%tky
                        %state_area       = 'VALIDATE_QUANTITY'
                        %path             = VALUE #( SalesOrder-%is_draft = item-%is_draft
                                                     SalesOrder-OrderUUID = item-OrderUUID )
                        %msg              = new_message_with_text(
                                              severity = if_abap_behv_message=>severity-error
                                              text     = 'Quantity must be greater than zero' )
                        %element-Quantity = if_abap_behv=>mk-on ) TO reported-salesorderitem.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
