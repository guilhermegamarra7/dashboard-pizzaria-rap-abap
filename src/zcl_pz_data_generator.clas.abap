CLASS zcl_pz_data_generator DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.


CLASS zcl_pz_data_generator IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    DELETE FROM zpz_order_item.
    DELETE FROM zpz_order.
    DELETE FROM zpz_recipe.
    DELETE FROM zpz_menu_item.
    DELETE FROM zpz_channel.

    INSERT zpz_channel FROM TABLE @( VALUE #(
      ( channel = 'IFOOD'    channel_name = 'iFood'             is_sales_channel = abap_true  platform_fee_pct = '24.96' )
      ( channel = '99FOOD'   channel_name = '99Food'            is_sales_channel = abap_true  platform_fee_pct = '20.73' )
      ( channel = 'WHATSAPP' channel_name = 'WhatsApp'          is_sales_channel = abap_true  platform_fee_pct = '0' )
      ( channel = 'HOUSE'    channel_name = 'House consumption' is_sales_channel = abap_false platform_fee_pct = '0' ) ) ).

    INSERT zpz_menu_item FROM TABLE @( VALUE #( currency = 'BRL' is_active = abap_true
      ( menu_item_id = 'MOZZARELLA'        item_name = 'Mozzarella'                item_type = 'PIZZA' price = '35.00' )
      ( menu_item_id = 'MARGHERITA'        item_name = 'Margherita'                item_type = 'PIZZA' price = '39.80' )
      ( menu_item_id = 'CALABRESE'         item_name = 'Calabrese'                 item_type = 'PIZZA' price = '43.40' )
      ( menu_item_id = 'BACON_ONION'       item_name = 'Bacon & Caramelized Onion' item_type = 'PIZZA' price = '49.40' )
      ( menu_item_id = 'PEPPERONI'         item_name = 'Pepperoni'                 item_type = 'PIZZA' price = '48.80' )
      ( menu_item_id = 'PEPPERONI_CHEDDAR' item_name = 'Pepperoni & Cheddar'       item_type = 'PIZZA' price = '52.60' )
      ( menu_item_id = 'QUATTRO_FORMAGGI'  item_name = 'Quattro Formaggi'          item_type = 'PIZZA' price = '50.50' )
      ( menu_item_id = 'CHICKEN_CATUPIRY'  item_name = 'Chicken & Catupiry'        item_type = 'PIZZA' price = '49.90' )
      ( menu_item_id = 'HAZELNUT_NINHO'    item_name = 'Hazelnut & Ninho'          item_type = 'PIZZA' price = '31.20' )
      ( menu_item_id = 'COKE_CAN'          item_name = 'Coca-Cola can 350ml'       item_type = 'DRINK' price = '8.00' )
      ( menu_item_id = 'HEINEKEN_473'      item_name = 'Heineken can 473ml'        item_type = 'DRINK' price = '13.90' ) ) ).

    INSERT zpz_recipe FROM TABLE @( VALUE #( currency = 'BRL'
      ( menu_item_id = 'MOZZARELLA'  component_no = '01' component = 'Pizza dough'        cost = '2.30' )
      ( menu_item_id = 'MOZZARELLA'  component_no = '02' component = 'Tomato sauce'       cost = '1.49' )
      ( menu_item_id = 'MOZZARELLA'  component_no = '03' component = 'Cheese'             cost = '4.40' )
      ( menu_item_id = 'MOZZARELLA'  component_no = '04' component = 'Box'                cost = '2.76' )
      ( menu_item_id = 'MARGHERITA'  component_no = '01' component = 'Pizza dough'        cost = '2.30' )
      ( menu_item_id = 'MARGHERITA'  component_no = '02' component = 'Tomato sauce'       cost = '1.49' )
      ( menu_item_id = 'MARGHERITA'  component_no = '03' component = 'Buffalo mozzarella' cost = '7.77' )
      ( menu_item_id = 'MARGHERITA'  component_no = '04' component = 'Box'                cost = '2.76' )
      ( menu_item_id = 'CALABRESE'   component_no = '01' component = 'Pizza dough'        cost = '2.30' )
      ( menu_item_id = 'CALABRESE'   component_no = '02' component = 'Tomato sauce'       cost = '1.49' )
      ( menu_item_id = 'CALABRESE'   component_no = '03' component = 'Cheese'             cost = '4.40' )
      ( menu_item_id = 'CALABRESE'   component_no = '04' component = 'Calabrese sausage'  cost = '3.85' )
      ( menu_item_id = 'CALABRESE'   component_no = '05' component = 'Box'                cost = '2.76' )
      ( menu_item_id = 'BACON_ONION' component_no = '01' component = 'Pizza dough'        cost = '2.30' )
      ( menu_item_id = 'BACON_ONION' component_no = '02' component = 'Tomato sauce'       cost = '1.49' )
      ( menu_item_id = 'BACON_ONION' component_no = '03' component = 'Cheese'             cost = '4.40' )
      ( menu_item_id = 'BACON_ONION' component_no = '04' component = 'Bacon'              cost = '4.18' )
      ( menu_item_id = 'BACON_ONION' component_no = '05' component = 'Caramelized onion'  cost = '2.09' )
      ( menu_item_id = 'BACON_ONION' component_no = '06' component = 'Box'                cost = '2.76' )
      ( menu_item_id = 'PEPPERONI'   component_no = '01' component = 'Pizza dough'        cost = '2.30' )
      ( menu_item_id = 'PEPPERONI'   component_no = '02' component = 'Tomato sauce'       cost = '1.49' )
      ( menu_item_id = 'PEPPERONI'   component_no = '03' component = 'Cheese'             cost = '4.40' )
      ( menu_item_id = 'PEPPERONI'   component_no = '04' component = 'Pepperoni'          cost = '5.30' )
      ( menu_item_id = 'PEPPERONI'   component_no = '05' component = 'Box'                cost = '2.76' ) ) ).

    DATA now TYPE timestampl.
    GET TIME STAMP FIELD now.
    DATA(current_user) = cl_abap_context_info=>get_user_technical_name( ).
    DATA orders TYPE STANDARD TABLE OF zpz_order WITH EMPTY KEY.

    TRY.
        orders = VALUE #( currency = 'BRL' delivery_type = 'DELIVERY'
                          local_created_by = current_user local_created_at = now
                          local_last_changed_by = current_user local_last_changed_at = now
                          last_changed_at = now
          ( order_uuid = cl_system_uuid=>create_uuid_x16_static( ) channel = 'IFOOD'
            external_id = '8ad4c4c4-8e8c-4727-8ffc-c65d4fa64f7e' order_datetime = '20260928002721' status = 'COMPLETED'
            items_amount = '99.30' delivery_fee = '7.99' store_discount = '4.99'
            platform_incentive = '5.75' platform_fees = '24.71' net_amount = '69.60' payment_method = 'Credit card' )
          ( order_uuid = cl_system_uuid=>create_uuid_x16_static( ) channel = 'IFOOD'
            external_id = '0a15681c-c95e-4c76-a82d-4b06816aaa50' order_datetime = '20260927234614' status = 'COMPLETED'
            items_amount = '132.60' delivery_fee = '10.99' store_discount = '4.99'
            platform_incentive = '5.86' platform_fees = '33.43' net_amount = '94.18' payment_method = 'Pix' )
          ( order_uuid = cl_system_uuid=>create_uuid_x16_static( ) channel = 'IFOOD'
            external_id = 'db5b24d8-ed3f-44c4-8d0c-236750b643c5' order_datetime = '20260927231725' status = 'COMPLETED'
            items_amount = '96.00' delivery_fee = '10.99' store_discount = '5.00'
            platform_incentive = '0' platform_fees = '23.84' net_amount = '67.16' payment_method = 'Pix' )
          ( order_uuid = cl_system_uuid=>create_uuid_x16_static( ) channel = '99FOOD'
            external_id = '5764672404794180874' order_datetime = '20260531000739' status = 'COMPLETED'
            items_amount = '83.20' store_discount = '9.99' platform_incentive = '23.00'
            platform_fees = '17.07' net_amount = '56.14' )
          ( order_uuid = cl_system_uuid=>create_uuid_x16_static( ) channel = '99FOOD'
            external_id = '5764672207762554960' order_datetime = '20260528225441' status = 'CANCELLED'
            cancel_reason = 'Not accepted within 10 minutes (auto-cancelled)' items_amount = '58.20' ) ).
      CATCH cx_uuid_error.
        out->write( 'Error while generating UUIDs' ).
        RETURN.
    ENDTRY.

    INSERT zpz_order FROM TABLE @orders.

    out->write( |Demo data generated: { lines( orders ) } sales orders.| ).
  ENDMETHOD.

ENDCLASS.
