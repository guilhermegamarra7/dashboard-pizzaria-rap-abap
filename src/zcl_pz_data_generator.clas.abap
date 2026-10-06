"! Loads the demo data: sales channels, menu, recipe costs and the real iFood and 99Food
"! orders from May to October 2026 (customer data removed). Run it with F9.
"! It deletes and reloads every ZPZ_* table.
"!
"! The platform reports do not list the items of each order, so every order gets the menu
"! items whose current prices add up to the order total. Orders placed before the price
"! change of late August keep the amount the customer actually paid.
CLASS zcl_pz_data_generator DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_order,
        order_no           TYPE i,
        channel            TYPE zpz_order-channel,
        external_id        TYPE zpz_order-external_id,
        order_datetime     TYPE zpz_order-order_datetime,
        status             TYPE zpz_order-status,
        cancel_reason      TYPE zpz_order-cancel_reason,
        items_amount       TYPE zpz_order-items_amount,
        delivery_fee       TYPE zpz_order-delivery_fee,
        store_discount     TYPE zpz_order-store_discount,
        platform_incentive TYPE zpz_order-platform_incentive,
        platform_fees      TYPE zpz_order-platform_fees,
        net_amount         TYPE zpz_order-net_amount,
        payment_method     TYPE zpz_order-payment_method,
        rating             TYPE zpz_order-rating,
        customer_comment   TYPE zpz_order-customer_comment,
      END OF ty_order,
      tt_orders TYPE STANDARD TABLE OF ty_order WITH EMPTY KEY,

      BEGIN OF ty_item,
        order_no     TYPE i,
        menu_item_id TYPE zpz_order_item-menu_item_id,
        quantity     TYPE zpz_order_item-quantity,
        total_amount TYPE zpz_order_item-total_amount,
      END OF ty_item,
      tt_items TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY.

    METHODS delete_all.
    METHODS insert_master_data.
    METHODS insert_orders
      RETURNING VALUE(result) TYPE i
      RAISING   cx_uuid_error.
    METHODS get_orders
      RETURNING VALUE(result) TYPE tt_orders.
    METHODS get_items
      RETURNING VALUE(result) TYPE tt_items.
ENDCLASS.


CLASS zcl_pz_data_generator IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    delete_all( ).
    insert_master_data( ).

    TRY.
        DATA(order_count) = insert_orders( ).
      CATCH cx_uuid_error.
        out->write( 'Error while generating UUIDs' ).
        RETURN.
    ENDTRY.

    out->write( |Demo data generated: { order_count } sales orders.| ).
  ENDMETHOD.


  METHOD delete_all.
    " Drafts point to orders that are about to be deleted
    DELETE FROM zpz_order_item_d.
    DELETE FROM zpz_order_d.
    DELETE FROM zpz_order_item.
    DELETE FROM zpz_order.
    DELETE FROM zpz_recipe.
    DELETE FROM zpz_menu_item.
    DELETE FROM zpz_channel.
  ENDMETHOD.


  METHOD insert_master_data.
    INSERT zpz_channel FROM TABLE @( VALUE #(
      ( channel = 'IFOOD'    channel_name = 'iFood'             is_sales_channel = abap_true  platform_fee_pct = '24.96' )
      ( channel = '99FOOD'   channel_name = '99Food'            is_sales_channel = abap_true  platform_fee_pct = '20.73' )
      ( channel = 'WHATSAPP' channel_name = 'WhatsApp'          is_sales_channel = abap_true  platform_fee_pct = '0' )
      ( channel = 'HOUSE'    channel_name = 'House consumption' is_sales_channel = abap_false platform_fee_pct = '0' ) ) ).

    INSERT zpz_menu_item FROM TABLE @( VALUE #( currency = 'BRL' is_active = abap_true
      ( menu_item_id = 'MOZZARELLA'           item_name = 'Mozzarella'                        item_type = 'PIZZA' price = '35.00' )
      ( menu_item_id = 'MARGHERITA'           item_name = 'Margherita'                        item_type = 'PIZZA' price = '39.80' )
      ( menu_item_id = 'CALABRESE'            item_name = 'Calabrese'                         item_type = 'PIZZA' price = '43.40' )
      ( menu_item_id = 'BACON_ONION'          item_name = 'Bacon & Caramelized Onion'         item_type = 'PIZZA' price = '49.40' )
      ( menu_item_id = 'PEPPERONI'            item_name = 'Pepperoni'                         item_type = 'PIZZA' price = '48.80' )
      ( menu_item_id = 'PEPPERONI_CHEDDAR'    item_name = 'Pepperoni & Cheddar'               item_type = 'PIZZA' price = '52.60' )
      ( menu_item_id = 'QUATTRO_FORMAGGI'     item_name = 'Quattro Formaggi'                  item_type = 'PIZZA' price = '50.50' )
      ( menu_item_id = 'CHICKEN_CATUPIRY'     item_name = 'Chicken & Catupiry'                item_type = 'PIZZA' price = '49.90' )
      ( menu_item_id = 'HAZELNUT_NINHO'       item_name = 'Hazelnut & Ninho'                  item_type = 'PIZZA' price = '31.20' )
      ( menu_item_id = 'COMBO_BACON_HAZELNUT' item_name = 'Combo Bacon + Hazelnut + 2 drinks' item_type = 'COMBO' price = '106.00' )
      ( menu_item_id = 'COKE_CAN'             item_name = 'Coca-Cola can 350ml'               item_type = 'DRINK' price = '8.00' )
      ( menu_item_id = 'COKE_ZERO_CAN'        item_name = 'Coca-Cola Zero can 350ml'          item_type = 'DRINK' price = '8.00' )
      ( menu_item_id = 'GUARANA_CAN'          item_name = 'Guarana Antarctica can 350ml'      item_type = 'DRINK' price = '8.00' )
      ( menu_item_id = 'GUARANA_ZERO_CAN'     item_name = 'Guarana Zero can 350ml'            item_type = 'DRINK' price = '8.00' )
      ( menu_item_id = 'HEINEKEN_473'         item_name = 'Heineken can 473ml'                item_type = 'DRINK' price = '13.90' )
      is_active = abap_false
      ( menu_item_id = 'PARMA_BRIE'           item_name = 'Parma, Brie & Jabuticaba Jam'      item_type = 'PIZZA' price = '55.00' ) ) ).

    " Costs come from the owner's cost sheet. Cheddar, catupiry, chicken, hazelnut cream,
    " Ninho and Heineken are recipe quantity x price per kg (or unit) from purchase invoices,
    " except chicken and Ninho, which are the owner's estimates.
    INSERT zpz_recipe FROM TABLE @( VALUE #( currency = 'BRL'
      ( menu_item_id = 'MOZZARELLA'        component_no = '01' component = 'Pizza dough'        cost = '2.30' )
      ( menu_item_id = 'MOZZARELLA'        component_no = '02' component = 'Tomato sauce'       cost = '1.49' )
      ( menu_item_id = 'MOZZARELLA'        component_no = '03' component = 'Cheese'             cost = '4.40' )
      ( menu_item_id = 'MOZZARELLA'        component_no = '04' component = 'Box'                cost = '2.76' )
      ( menu_item_id = 'MARGHERITA'        component_no = '01' component = 'Pizza dough'        cost = '2.30' )
      ( menu_item_id = 'MARGHERITA'        component_no = '02' component = 'Tomato sauce'       cost = '1.49' )
      ( menu_item_id = 'MARGHERITA'        component_no = '03' component = 'Buffalo mozzarella' cost = '7.77' )
      ( menu_item_id = 'MARGHERITA'        component_no = '04' component = 'Box'                cost = '2.76' )
      ( menu_item_id = 'CALABRESE'         component_no = '01' component = 'Pizza dough'        cost = '2.30' )
      ( menu_item_id = 'CALABRESE'         component_no = '02' component = 'Tomato sauce'       cost = '1.49' )
      ( menu_item_id = 'CALABRESE'         component_no = '03' component = 'Cheese'             cost = '4.40' )
      ( menu_item_id = 'CALABRESE'         component_no = '04' component = 'Calabrese sausage'  cost = '3.85' )
      ( menu_item_id = 'CALABRESE'         component_no = '05' component = 'Box'                cost = '2.76' )
      ( menu_item_id = 'BACON_ONION'       component_no = '01' component = 'Pizza dough'        cost = '2.30' )
      ( menu_item_id = 'BACON_ONION'       component_no = '02' component = 'Tomato sauce'       cost = '1.49' )
      ( menu_item_id = 'BACON_ONION'       component_no = '03' component = 'Cheese'             cost = '4.40' )
      ( menu_item_id = 'BACON_ONION'       component_no = '04' component = 'Bacon'              cost = '4.18' )
      ( menu_item_id = 'BACON_ONION'       component_no = '05' component = 'Caramelized onion'  cost = '2.09' )
      ( menu_item_id = 'BACON_ONION'       component_no = '06' component = 'Box'                cost = '2.76' )
      ( menu_item_id = 'PEPPERONI'         component_no = '01' component = 'Pizza dough'        cost = '2.30' )
      ( menu_item_id = 'PEPPERONI'         component_no = '02' component = 'Tomato sauce'       cost = '1.49' )
      ( menu_item_id = 'PEPPERONI'         component_no = '03' component = 'Cheese'             cost = '4.40' )
      ( menu_item_id = 'PEPPERONI'         component_no = '04' component = 'Pepperoni'          cost = '5.30' )
      ( menu_item_id = 'PEPPERONI'         component_no = '05' component = 'Box'                cost = '2.76' )
      ( menu_item_id = 'PEPPERONI_CHEDDAR' component_no = '01' component = 'Pizza dough'        cost = '2.30' )
      ( menu_item_id = 'PEPPERONI_CHEDDAR' component_no = '02' component = 'Tomato sauce'       cost = '1.49' )
      ( menu_item_id = 'PEPPERONI_CHEDDAR' component_no = '03' component = 'Cheese'             cost = '4.40' )
      ( menu_item_id = 'PEPPERONI_CHEDDAR' component_no = '04' component = 'Pepperoni'          cost = '5.30' )
      ( menu_item_id = 'PEPPERONI_CHEDDAR' component_no = '05' component = 'Cheddar'            cost = '0.72' )
      ( menu_item_id = 'PEPPERONI_CHEDDAR' component_no = '06' component = 'Box'                cost = '2.76' )
      ( menu_item_id = 'QUATTRO_FORMAGGI'  component_no = '01' component = 'Pizza dough'        cost = '2.30' )
      ( menu_item_id = 'QUATTRO_FORMAGGI'  component_no = '02' component = 'Tomato sauce'       cost = '1.49' )
      ( menu_item_id = 'QUATTRO_FORMAGGI'  component_no = '03' component = 'Cheese'             cost = '4.40' )
      ( menu_item_id = 'QUATTRO_FORMAGGI'  component_no = '04' component = 'Gorgonzola'         cost = '2.20' )
      ( menu_item_id = 'QUATTRO_FORMAGGI'  component_no = '05' component = 'Provolone'          cost = '2.00' )
      ( menu_item_id = 'QUATTRO_FORMAGGI'  component_no = '06' component = 'Catupiry'           cost = '1.67' )
      ( menu_item_id = 'QUATTRO_FORMAGGI'  component_no = '07' component = 'Box'                cost = '2.76' )
      ( menu_item_id = 'CHICKEN_CATUPIRY'  component_no = '01' component = 'Pizza dough'        cost = '2.30' )
      ( menu_item_id = 'CHICKEN_CATUPIRY'  component_no = '02' component = 'Tomato sauce'       cost = '1.49' )
      ( menu_item_id = 'CHICKEN_CATUPIRY'  component_no = '03' component = 'Cheese'             cost = '4.40' )
      ( menu_item_id = 'CHICKEN_CATUPIRY'  component_no = '04' component = 'Shredded chicken'   cost = '3.00' )
      ( menu_item_id = 'CHICKEN_CATUPIRY'  component_no = '05' component = 'Catupiry'           cost = '0.73' )
      ( menu_item_id = 'CHICKEN_CATUPIRY'  component_no = '06' component = 'Box'                cost = '2.76' )
      ( menu_item_id = 'HAZELNUT_NINHO'    component_no = '01' component = 'Pizza dough'        cost = '2.30' )
      ( menu_item_id = 'HAZELNUT_NINHO'    component_no = '02' component = 'Hazelnut cream'     cost = '5.50' )
      ( menu_item_id = 'HAZELNUT_NINHO'    component_no = '03' component = 'Ninho powdered milk' cost = '1.30' )
      ( menu_item_id = 'HAZELNUT_NINHO'    component_no = '04' component = 'Box'                cost = '2.76' )
      ( menu_item_id = 'HEINEKEN_473'      component_no = '01' component = 'Heineken can 473ml' cost = '5.99' ) ) ).
  ENDMETHOD.


  METHOD insert_orders.
    DATA now TYPE timestampl.
    DATA db_orders TYPE STANDARD TABLE OF zpz_order WITH EMPTY KEY.
    DATA db_items TYPE STANDARD TABLE OF zpz_order_item WITH EMPTY KEY.

    GET TIME STAMP FIELD now.
    DATA(current_user) = cl_abap_context_info=>get_user_technical_name( ).
    DATA(items) = get_items( ).

    LOOP AT get_orders( ) INTO DATA(order).
      DATA(order_uuid) = cl_system_uuid=>create_uuid_x16_static( ).
      DATA(item_count) = 0.

      LOOP AT items INTO DATA(item) WHERE order_no = order-order_no.
        APPEND VALUE #( item_uuid             = cl_system_uuid=>create_uuid_x16_static( )
                        order_uuid            = order_uuid
                        menu_item_id          = item-menu_item_id
                        quantity              = item-quantity
                        total_amount          = item-total_amount
                        currency              = 'BRL'
                        local_last_changed_at = now ) TO db_items.
        item_count += item-quantity.
      ENDLOOP.

      APPEND VALUE #( BASE CORRESPONDING #( order )
                      order_uuid            = order_uuid
                      currency              = 'BRL'
                      item_count            = item_count
                      delivery_type         = 'DELIVERY'
                      local_created_by      = current_user
                      local_created_at      = now
                      local_last_changed_by = current_user
                      local_last_changed_at = now
                      last_changed_at       = now ) TO db_orders.
    ENDLOOP.

    INSERT zpz_order FROM TABLE @db_orders.
    INSERT zpz_order_item FROM TABLE @db_items.
    result = lines( db_orders ).
  ENDMETHOD.


  METHOD get_orders.
    " Order date/times are in UTC (the pizzeria is in UTC-3).
    result = VALUE #(
      ( order_no = 1 channel = 'IFOOD' external_id = '8ad4c4c4-8e8c-4727-8ffc-c65d4fa64f7e' order_datetime = '20260928002721' status = 'COMPLETED'
        items_amount = '99.30' delivery_fee = '7.99' store_discount = '4.99' platform_incentive = '5.75' platform_fees = '24.71' net_amount = '69.60'
        payment_method = 'Credit card' )
      ( order_no = 2 channel = 'IFOOD' external_id = '0a15681c-c95e-4c76-a82d-4b06816aaa50' order_datetime = '20260927234614' status = 'COMPLETED'
        items_amount = '132.60' delivery_fee = '10.99' store_discount = '4.99' platform_incentive = '5.86' platform_fees = '33.43' net_amount = '94.18'
        payment_method = 'Pix' )
      ( order_no = 3 channel = 'IFOOD' external_id = 'db5b24d8-ed3f-44c4-8d0c-236750b643c5' order_datetime = '20260927231725' status = 'COMPLETED'
        items_amount = '96.00' delivery_fee = '10.99' store_discount = '5.00' platform_fees = '23.84' net_amount = '67.16'
        payment_method = 'Pix' )
      ( order_no = 4 channel = 'IFOOD' external_id = 'e7672d84-3136-40ea-9761-853e5185c88f' order_datetime = '20260927221921' status = 'COMPLETED'
        items_amount = '35.00' delivery_fee = '7.99' store_discount = '5.00' platform_incentive = '7.99' platform_fees = '7.86' net_amount = '22.14'
        payment_method = 'Pix' )
      ( order_no = 5 channel = 'IFOOD' external_id = 'e79c06c5-8f98-488f-a5c9-464114593206' order_datetime = '20260927001005' status = 'COMPLETED'
        items_amount = '35.00' delivery_fee = '9.99' store_discount = '5.00' platform_incentive = '7.25' platform_fees = '7.86' net_amount = '22.14'
        payment_method = 'Credit card' )
      ( order_no = 6 channel = 'IFOOD' external_id = '6062770c-f475-4a86-9313-6fd8122e31d2' order_datetime = '20260926225303' status = 'COMPLETED'
        items_amount = '121.50' delivery_fee = '7.99' store_discount = '4.99' platform_incentive = '7.49' platform_fees = '30.53' net_amount = '85.98'
        payment_method = 'Credit card' )
      ( order_no = 7 channel = 'IFOOD' external_id = '5faea4e4-fb16-43bc-a97e-e491d9c29219' order_datetime = '20260926223349' status = 'COMPLETED'
        items_amount = '99.30' delivery_fee = '9.99' platform_incentive = '9.99' platform_fees = '26.02' net_amount = '73.28'
        payment_method = 'Debit card' )
      ( order_no = 8 channel = 'IFOOD' external_id = '80f9a78e-f404-4640-8e9b-96cec7722344' order_datetime = '20260926221913' status = 'COMPLETED'
        items_amount = '163.80' delivery_fee = '23.98' platform_fees = '42.91' net_amount = '120.89'
        payment_method = 'Credit card' )
      ( order_no = 9 channel = 'IFOOD' external_id = 'd918ca48-8ea4-49f4-941b-bfa096065f56' order_datetime = '20260926001213' status = 'COMPLETED'
        items_amount = '89.20' delivery_fee = '9.99' store_discount = '5.00' platform_incentive = '7.35' platform_fees = '22.06' net_amount = '62.14'
        payment_method = 'Digital wallet' )
      ( order_no = 10 channel = 'IFOOD' external_id = '6ee981e0-00df-4f0a-a0c4-1f659b1cf605' order_datetime = '20260920230148' status = 'COMPLETED'
        items_amount = '64.80' delivery_fee = '10.99' store_discount = '5.00' platform_fees = '15.66' net_amount = '44.14'
        payment_method = 'Pix' )
      ( order_no = 11 channel = 'IFOOD' external_id = '052ac6cc-d244-4b7b-bebb-b0f2225b82fb' order_datetime = '20260920000926' status = 'COMPLETED'
        items_amount = '43.40' delivery_fee = '10.99' store_discount = '4.99' platform_incentive = '5.86' platform_fees = '10.06' net_amount = '28.35'
        payment_method = 'Credit card' )
      ( order_no = 12 channel = 'IFOOD' external_id = '0c630d90-de44-4e51-a9bd-9a0c67677919' order_datetime = '20260919234900' status = 'COMPLETED'
        items_amount = '35.00' delivery_fee = '10.99' store_discount = '4.99' platform_incentive = '4.46' platform_fees = '7.86' net_amount = '22.15'
        payment_method = 'Pix' )
      ( order_no = 13 channel = 'IFOOD' external_id = '1ae9ade8-a349-473f-a292-277a6b6b7057' order_datetime = '20260919232232' status = 'COMPLETED'
        items_amount = '143.30' delivery_fee = '8.99' store_discount = '5.00' platform_incentive = '7.35' platform_fees = '36.24' net_amount = '102.06'
        payment_method = 'Credit card' )
      ( order_no = 14 channel = 'IFOOD' external_id = 'e1b9a0f2-7d5e-49b0-ba0f-f756925bc08b' order_datetime = '20260919223817' status = 'COMPLETED'
        items_amount = '124.20' delivery_fee = '8.99' store_discount = '4.99' platform_incentive = '17.93' platform_fees = '31.23' net_amount = '87.98'
        payment_method = 'Credit card' )
      ( order_no = 15 channel = 'IFOOD' external_id = 'd8fc1aff-7e6f-4728-b62b-0e3655b78258' order_datetime = '20260919004522' status = 'COMPLETED'
        items_amount = '167.90' delivery_fee = '11.99' platform_fees = '43.99' net_amount = '123.91'
        payment_method = 'Pix' )
      ( order_no = 16 channel = 'IFOOD' external_id = 'd50df68e-913d-4edf-8fa6-b102b3800680' order_datetime = '20260919003325' status = 'COMPLETED'
        items_amount = '43.40' delivery_fee = '7.99' store_discount = '5.00' platform_incentive = '10.19' platform_fees = '10.06' net_amount = '28.34'
        payment_method = 'Credit card' )
      ( order_no = 17 channel = 'IFOOD' external_id = '678eac25-637a-4822-8cd7-05d77997d929' order_datetime = '20260919001452' status = 'COMPLETED'
        items_amount = '88.60' delivery_fee = '7.99' store_discount = '5.00' platform_incentive = '12.99' platform_fees = '21.91' net_amount = '61.69'
        payment_method = 'Credit card' )
      ( order_no = 18 channel = 'IFOOD' external_id = 'aab3c984-c853-4f6e-8ce6-35c346e159f5' order_datetime = '20260918233443' status = 'COMPLETED'
        items_amount = '109.60' delivery_fee = '10.99' store_discount = '4.99' platform_incentive = '5.86' platform_fees = '27.41' net_amount = '77.20'
        payment_method = 'Digital wallet' )
      ( order_no = 19 channel = 'IFOOD' external_id = '13b1c06a-37a0-4743-b884-69fd4bceaebd' order_datetime = '20260913235051' status = 'COMPLETED'
        items_amount = '43.40' delivery_fee = '6.99' store_discount = '4.99' platform_incentive = '6.73' platform_fees = '10.06' net_amount = '28.35'
        payment_method = 'Credit card' )
      ( order_no = 20 channel = 'IFOOD' external_id = '1e2b87f6-90fb-48eb-8922-566af55eb280' order_datetime = '20260912004704' status = 'COMPLETED'
        items_amount = '118.00' delivery_fee = '11.99' store_discount = '5.00' platform_incentive = '5.92' platform_fees = '29.61' net_amount = '83.39'
        payment_method = 'Pix' )
      ( order_no = 21 channel = 'IFOOD' external_id = '446ef2a1-8698-40bc-9e94-685c8f1c8201' order_datetime = '20260912002343' status = 'COMPLETED'
        items_amount = '48.80' delivery_fee = '7.99' store_discount = '5.00' platform_incentive = '7.99' platform_fees = '11.47' net_amount = '32.33'
        payment_method = 'Credit card' )
      ( order_no = 22 channel = 'IFOOD' external_id = 'd8b2e85a-a157-4ab1-ae42-ca94a138af8c' order_datetime = '20260911234005' status = 'COMPLETED'
        items_amount = '92.80' delivery_fee = '9.99' platform_fees = '24.31' net_amount = '68.49'
        payment_method = 'Debit card' )
      ( order_no = 23 channel = 'IFOOD' external_id = 'd8f7e036-9334-4686-b7fe-acb13a253122' order_datetime = '20260905225548' status = 'COMPLETED'
        items_amount = '35.00' delivery_fee = '6.99' store_discount = '5.00' platform_incentive = '7.25' platform_fees = '7.86' net_amount = '22.14'
        payment_method = 'Pix' )
      ( order_no = 24 channel = 'IFOOD' external_id = 'b7909ee5-92df-43bb-9c89-9c570876de5b' order_datetime = '20260905223245' status = 'COMPLETED'
        items_amount = '39.80' delivery_fee = '6.99' platform_fees = '10.42' net_amount = '29.38'
        payment_method = 'Bank app' )
      ( order_no = 25 channel = 'IFOOD' external_id = '6b267852-d96b-4521-9fd1-ecc57b7158f5' order_datetime = '20260905004929' status = 'COMPLETED'
        items_amount = '31.20' delivery_fee = '6.99' store_discount = '5.00' platform_incentive = '9.79' platform_fees = '6.87' net_amount = '19.33'
        payment_method = 'Pix' )
      ( order_no = 26 channel = 'IFOOD' external_id = 'ec3ca30b-ddfc-434e-8b4a-0bb733d2bb94' order_datetime = '20260905002053' status = 'COMPLETED'
        items_amount = '35.00' delivery_fee = '8.99' store_discount = '5.00' platform_incentive = '7.25' platform_fees = '7.86' net_amount = '22.14'
        payment_method = 'Digital wallet' )
      ( order_no = 27 channel = 'IFOOD' external_id = '1779aeaa-2056-4739-b072-555eca63d43f' order_datetime = '20261003004500' status = 'COMPLETED'
        items_amount = '81.70' delivery_fee = '17.99' platform_fees = '21.40' net_amount = '60.30'
        payment_method = 'Credit card' )
      ( order_no = 28 channel = '99FOOD' external_id = '5764672404794180874' order_datetime = '20260531000739' status = 'COMPLETED'
        items_amount = '83.20' store_discount = '9.99' platform_incentive = '23.00' platform_fees = '17.07' net_amount = '56.14'
        payment_method = 'Online payment' rating = 2 )
      ( order_no = 29 channel = '99FOOD' external_id = '5764672207762554960' order_datetime = '20260528225441' status = 'CANCELLED' cancel_reason = 'Not accepted within 10 minutes (auto-cancelled)'
        items_amount = '58.20'
        payment_method = 'Online payment' )
      ( order_no = 30 channel = '99FOOD' external_id = '5764671797588986111' order_datetime = '20260525010022' status = 'COMPLETED'
        items_amount = '206.80' store_discount = '2.99' platform_incentive = '40.00' platform_fees = '29.02' net_amount = '174.79'
        payment_method = 'Online payment' rating = 5
        customer_comment = 'Would recommend, excellent food, attentive service, well packaged' )
      ( order_no = 31 channel = '99FOOD' external_id = '5764671780769826848' order_datetime = '20260524235847' status = 'COMPLETED'
        items_amount = '43.40' store_discount = '5.99' platform_incentive = '16.00' platform_fees = '10.25' net_amount = '27.16'
        payment_method = 'Online payment' )
      ( order_no = 32 channel = '99FOOD' external_id = '5764671584707086376' order_datetime = '20260524235312' status = 'COMPLETED'
        items_amount = '39.80' store_discount = '2.99' platform_incentive = '13.00' platform_fees = '9.82' net_amount = '26.99'
        payment_method = 'Online payment' )
      ( order_no = 33 channel = '99FOOD' external_id = '5764671590017073232' order_datetime = '20260524002449' status = 'COMPLETED'
        items_amount = '41.40' store_discount = '3.99' platform_incentive = '18.00' platform_fees = '10.01' net_amount = '27.40'
        payment_method = 'Online payment' )
      ( order_no = 34 channel = '99FOOD' external_id = '5764671550527705079' order_datetime = '20260523235703' status = 'COMPLETED'
        items_amount = '49.40' store_discount = '5.99' platform_incentive = '15.00' platform_fees = '10.98' net_amount = '32.43'
        payment_method = 'Online payment' rating = 5
        customer_comment = 'Very good | Excellent food' )
      ( order_no = 35 channel = '99FOOD' external_id = '5764670667073062076' order_datetime = '20260515224727' status = 'COMPLETED'
        items_amount = '58.20' store_discount = '1.99' platform_fees = '11.04' net_amount = '45.17'
        payment_method = 'Online payment' )
      ( order_no = 36 channel = '99FOOD' external_id = '5764676390314117257' order_datetime = '20260630233231' status = 'COMPLETED'
        items_amount = '39.00' store_discount = '2.99' platform_incentive = '4.00' platform_fees = '9.22' net_amount = '26.79'
        payment_method = 'Online payment' )
      ( order_no = 37 channel = '99FOOD' external_id = '5764676091209908618' order_datetime = '20260628000302' status = 'CANCELLED' cancel_reason = 'Courier issue'
        items_amount = '43.40'
        payment_method = 'Online payment' )
      ( order_no = 38 channel = '99FOOD' external_id = '5764675471124007062' order_datetime = '20260624231003' status = 'COMPLETED'
        items_amount = '78.80' store_discount = '9.99' platform_incentive = '25.01' platform_fees = '19.04' net_amount = '49.77'
        payment_method = 'Online payment' rating = 1
        customer_comment = 'Ordered one of each flavor, got two of the same | Wrong item delivered' )
      ( order_no = 39 channel = '99FOOD' external_id = '5764675236788242178' order_datetime = '20260622004428' status = 'COMPLETED'
        items_amount = '90.80' store_discount = '3.99' platform_incentive = '25.00' platform_fees = '14.99' net_amount = '71.82'
        payment_method = 'Online payment' )
      ( order_no = 40 channel = '99FOOD' external_id = '5764675190025946475' order_datetime = '20260621225302' status = 'COMPLETED'
        items_amount = '108.80' store_discount = '2.99' platform_incentive = '25.00' platform_fees = '17.17' net_amount = '88.64'
        payment_method = 'Online payment' rating = 4 )
      ( order_no = 41 channel = '99FOOD' external_id = '5764674759702937973' order_datetime = '20260616235814' status = 'COMPLETED'
        items_amount = '65.30' store_discount = '9.99' platform_incentive = '15.00' platform_fees = '14.40' net_amount = '40.91'
        payment_method = 'Online payment' )
      ( order_no = 42 channel = '99FOOD' external_id = '5764674317493273670' order_datetime = '20260613002743' status = 'COMPLETED'
        items_amount = '39.80' store_discount = '2.99' platform_incentive = '8.00' platform_fees = '11.82' net_amount = '24.99'
        payment_method = 'Online payment' )
      ( order_no = 43 channel = '99FOOD' external_id = '5764674314347545092' order_datetime = '20260612223306' status = 'COMPLETED'
        items_amount = '39.80' store_discount = '2.99' platform_incentive = '7.01' platform_fees = '11.82' net_amount = '24.99'
        payment_method = 'Online payment' )
      ( order_no = 44 channel = '99FOOD' external_id = '5764680706030633624' order_datetime = '20260803000731' status = 'COMPLETED'
        items_amount = '107.60' store_discount = '9.99' platform_incentive = '41.00' platform_fees = '22.02' net_amount = '75.59'
        payment_method = 'Online payment' rating = 5 )
      ( order_no = 45 channel = '99FOOD' external_id = '5764680898054259369' order_datetime = '20260803000534' status = 'CANCELLED' cancel_reason = 'Cancelled right after ordering'
        items_amount = '107.60'
        payment_method = 'Online payment' )
      ( order_no = 46 channel = '99FOOD' external_id = '5764679743572085436' order_datetime = '20260726233822' status = 'COMPLETED'
        items_amount = '47.00' store_discount = '7.99' platform_incentive = '15.00' platform_fees = '10.69' net_amount = '28.32'
        payment_method = 'Online payment' )
      ( order_no = 47 channel = '99FOOD' external_id = '5764679789533268434' order_datetime = '20260726223608' status = 'COMPLETED'
        items_amount = '43.40' store_discount = '3.99' platform_incentive = '16.00' platform_fees = '11.75' net_amount = '27.66'
        payment_method = 'Online payment' )
      ( order_no = 48 channel = '99FOOD' external_id = '5764679670331147026' order_datetime = '20260726004211' status = 'COMPLETED'
        items_amount = '84.80' store_discount = '9.99' platform_incentive = '37.00' platform_fees = '19.26' net_amount = '55.55'
        payment_method = 'Online payment' )
      ( order_no = 49 channel = '99FOOD' external_id = '5764678878694016399' order_datetime = '20260719223302' status = 'COMPLETED'
        items_amount = '58.20' store_discount = '7.99' platform_incentive = '25.00' platform_fees = '12.54' net_amount = '37.67'
        payment_method = 'Online payment' rating = 3 )
      ( order_no = 50 channel = '99FOOD' external_id = '5764677953988395829' order_datetime = '20260712222706' status = 'COMPLETED'
        items_amount = '39.80' store_discount = '2.99' platform_incentive = '25.88' platform_fees = '8.32' net_amount = '28.49'
        payment_method = 'Online payment' )
      ( order_no = 51 channel = '99FOOD' external_id = '5764678051052978968' order_datetime = '20260712221833' status = 'COMPLETED'
        items_amount = '149.40' store_discount = '9.99' platform_incentive = '0.01' platform_fees = '29.58' net_amount = '109.83'
        payment_method = 'Online payment' )
      ( order_no = 52 channel = '99FOOD' external_id = '5764684561455841787' order_datetime = '20260830003129' status = 'COMPLETED'
        items_amount = '43.40' store_discount = '3.99' platform_incentive = '4.00' platform_fees = '10.25' net_amount = '29.16'
        payment_method = 'Online payment' rating = 3 )
      ( order_no = 53 channel = '99FOOD' external_id = '5764683695856353614' order_datetime = '20260824001043' status = 'COMPLETED'
        items_amount = '43.40' store_discount = '3.99' platform_incentive = '15.00' platform_fees = '10.25' net_amount = '29.16'
        payment_method = 'Online payment' rating = 5 )
      ( order_no = 54 channel = '99FOOD' external_id = '5764682155473047466' order_datetime = '20260814221751' status = 'COMPLETED'
        items_amount = '83.20' store_discount = '6.99' platform_fees = '16.07' net_amount = '60.14'
        payment_method = 'Online payment' )
      ( order_no = 55 channel = '99FOOD' external_id = '5764689636412689219' order_datetime = '20261004003028' status = 'CANCELLED' cancel_reason = 'Not accepted within 10 minutes (auto-cancelled)'
        items_amount = '43.40'
        payment_method = 'Online payment' )
      ( order_no = 56 channel = '99FOOD' external_id = '5764688815432206579' order_datetime = '20260927222658' status = 'COMPLETED'
        items_amount = '98.20' store_discount = '9.99' platform_incentive = '22.00' platform_fees = '20.38' net_amount = '67.83'
        payment_method = 'Online payment' )
      ( order_no = 57 channel = '99FOOD' external_id = '5764688341580711367' order_datetime = '20260925224108' status = 'COMPLETED'
        items_amount = '124.00' store_discount = '9.99' platform_incentive = '30.01' platform_fees = '25.00' net_amount = '89.01'
        payment_method = 'Online payment' )
      ( order_no = 58 channel = '99FOOD' external_id = '5764687484470496181' order_datetime = '20260918224945' status = 'COMPLETED'
        items_amount = '115.60' store_discount = '7.99' platform_fees = '21.98' net_amount = '85.63'
        payment_method = 'Online payment' )
      ( order_no = 59 channel = '99FOOD' external_id = '5764686688664224848' order_datetime = '20260913224905' status = 'COMPLETED'
        items_amount = '48.80' store_discount = '3.99' platform_incentive = '20.00' platform_fees = '9.41' net_amount = '35.40'
        payment_method = 'Online payment' rating = 5
        customer_comment = 'Great food quality, reasonable price, exactly as ordered, recommend to friends, attentive service, well packaged' )
      ( order_no = 60 channel = '99FOOD' external_id = '5764686524620800073' order_datetime = '20260911224114' status = 'COMPLETED'
        items_amount = '39.80' store_discount = '2.99' platform_incentive = '7.00' platform_fees = '10.82' net_amount = '25.99'
        payment_method = 'Online payment' )
      ( order_no = 61 channel = '99FOOD' external_id = '5764686475933319232' order_datetime = '20260911223039' status = 'CANCELLED' cancel_reason = 'Not accepted within 10 minutes (auto-cancelled)'
        items_amount = '39.80'
        payment_method = 'Online payment' )
      ( order_no = 62 channel = '99FOOD' external_id = '5764685394255875974' order_datetime = '20260906001805' status = 'COMPLETED'
        items_amount = '31.20' store_discount = '2.99' platform_incentive = '6.00' platform_fees = '9.77' net_amount = '18.44'
        payment_method = 'Online payment' )
      ( order_no = 63 channel = '99FOOD' external_id = '5764685546995650385' order_datetime = '20260906000657' status = 'COMPLETED'
        items_amount = '106.70' store_discount = '9.99' platform_fees = '21.41' net_amount = '75.30'
        payment_method = 'Online payment' rating = 5
        customer_comment = 'Very good pizza, tasty dough and toppings! Highly recommend!' )
      ).
  ENDMETHOD.


  METHOD get_items.
    result = VALUE #(
      ( order_no = 1 menu_item_id = 'BACON_ONION' quantity = 1 total_amount = '49.40' )
      ( order_no = 1 menu_item_id = 'CHICKEN_CATUPIRY' quantity = 1 total_amount = '49.90' )
      ( order_no = 2 menu_item_id = 'MOZZARELLA' quantity = 1 total_amount = '35.00' )
      ( order_no = 2 menu_item_id = 'PEPPERONI' quantity = 2 total_amount = '97.60' )
      ( order_no = 3 menu_item_id = 'CALABRESE' quantity = 1 total_amount = '43.40' )
      ( order_no = 3 menu_item_id = 'PEPPERONI_CHEDDAR' quantity = 1 total_amount = '52.60' )
      ( order_no = 4 menu_item_id = 'MOZZARELLA' quantity = 1 total_amount = '35.00' )
      ( order_no = 5 menu_item_id = 'MOZZARELLA' quantity = 1 total_amount = '35.00' )
      ( order_no = 6 menu_item_id = 'MARGHERITA' quantity = 1 total_amount = '39.80' )
      ( order_no = 6 menu_item_id = 'QUATTRO_FORMAGGI' quantity = 1 total_amount = '50.50' )
      ( order_no = 6 menu_item_id = 'HAZELNUT_NINHO' quantity = 1 total_amount = '31.20' )
      ( order_no = 7 menu_item_id = 'BACON_ONION' quantity = 1 total_amount = '49.40' )
      ( order_no = 7 menu_item_id = 'CHICKEN_CATUPIRY' quantity = 1 total_amount = '49.90' )
      ( order_no = 8 menu_item_id = 'MOZZARELLA' quantity = 1 total_amount = '35.00' )
      ( order_no = 8 menu_item_id = 'PEPPERONI' quantity = 2 total_amount = '97.60' )
      ( order_no = 8 menu_item_id = 'HAZELNUT_NINHO' quantity = 1 total_amount = '31.20' )
      ( order_no = 9 menu_item_id = 'MARGHERITA' quantity = 1 total_amount = '39.80' )
      ( order_no = 9 menu_item_id = 'BACON_ONION' quantity = 1 total_amount = '49.40' )
      ( order_no = 10 menu_item_id = 'PEPPERONI' quantity = 1 total_amount = '48.80' )
      ( order_no = 10 menu_item_id = 'COKE_CAN' quantity = 1 total_amount = '8.00' )
      ( order_no = 10 menu_item_id = 'GUARANA_CAN' quantity = 1 total_amount = '8.00' )
      ( order_no = 11 menu_item_id = 'CALABRESE' quantity = 1 total_amount = '43.40' )
      ( order_no = 12 menu_item_id = 'MOZZARELLA' quantity = 1 total_amount = '35.00' )
      ( order_no = 13 menu_item_id = 'CALABRESE' quantity = 1 total_amount = '43.40' )
      ( order_no = 13 menu_item_id = 'BACON_ONION' quantity = 1 total_amount = '49.40' )
      ( order_no = 13 menu_item_id = 'QUATTRO_FORMAGGI' quantity = 1 total_amount = '50.50' )
      ( order_no = 14 menu_item_id = 'MOZZARELLA' quantity = 1 total_amount = '35.00' )
      ( order_no = 14 menu_item_id = 'MARGHERITA' quantity = 1 total_amount = '39.80' )
      ( order_no = 14 menu_item_id = 'BACON_ONION' quantity = 1 total_amount = '49.40' )
      ( order_no = 15 menu_item_id = 'CALABRESE' quantity = 2 total_amount = '86.80' )
      ( order_no = 15 menu_item_id = 'CHICKEN_CATUPIRY' quantity = 1 total_amount = '49.90' )
      ( order_no = 15 menu_item_id = 'HAZELNUT_NINHO' quantity = 1 total_amount = '31.20' )
      ( order_no = 16 menu_item_id = 'CALABRESE' quantity = 1 total_amount = '43.40' )
      ( order_no = 17 menu_item_id = 'MARGHERITA' quantity = 1 total_amount = '39.80' )
      ( order_no = 17 menu_item_id = 'PEPPERONI' quantity = 1 total_amount = '48.80' )
      ( order_no = 18 menu_item_id = 'MOZZARELLA' quantity = 1 total_amount = '35.00' )
      ( order_no = 18 menu_item_id = 'CALABRESE' quantity = 1 total_amount = '43.40' )
      ( order_no = 18 menu_item_id = 'HAZELNUT_NINHO' quantity = 1 total_amount = '31.20' )
      ( order_no = 19 menu_item_id = 'CALABRESE' quantity = 1 total_amount = '43.40' )
      ( order_no = 20 menu_item_id = 'CALABRESE' quantity = 2 total_amount = '86.80' )
      ( order_no = 20 menu_item_id = 'HAZELNUT_NINHO' quantity = 1 total_amount = '31.20' )
      ( order_no = 21 menu_item_id = 'PEPPERONI' quantity = 1 total_amount = '48.80' )
      ( order_no = 22 menu_item_id = 'CALABRESE' quantity = 1 total_amount = '43.40' )
      ( order_no = 22 menu_item_id = 'BACON_ONION' quantity = 1 total_amount = '49.40' )
      ( order_no = 23 menu_item_id = 'MOZZARELLA' quantity = 1 total_amount = '35.00' )
      ( order_no = 24 menu_item_id = 'MARGHERITA' quantity = 1 total_amount = '39.80' )
      ( order_no = 25 menu_item_id = 'HAZELNUT_NINHO' quantity = 1 total_amount = '31.20' )
      ( order_no = 26 menu_item_id = 'MOZZARELLA' quantity = 1 total_amount = '35.00' )
      ( order_no = 27 menu_item_id = 'QUATTRO_FORMAGGI' quantity = 1 total_amount = '50.50' )
      ( order_no = 27 menu_item_id = 'HAZELNUT_NINHO' quantity = 1 total_amount = '31.20' )
      ( order_no = 28 menu_item_id = 'MOZZARELLA' quantity = 1 total_amount = '35.00' )
      ( order_no = 28 menu_item_id = 'MARGHERITA' quantity = 1 total_amount = '40.20' )
      ( order_no = 28 menu_item_id = 'COKE_CAN' quantity = 1 total_amount = '8.00' )
      ( order_no = 29 menu_item_id = 'PEPPERONI_CHEDDAR' quantity = 1 total_amount = '58.20' )
      ( order_no = 30 menu_item_id = 'CALABRESE' quantity = 1 total_amount = '43.40' )
      ( order_no = 30 menu_item_id = 'BACON_ONION' quantity = 1 total_amount = '49.40' )
      ( order_no = 30 menu_item_id = 'GUARANA_CAN' quantity = 1 total_amount = '8.00' )
      ( order_no = 30 menu_item_id = 'COMBO_BACON_HAZELNUT' quantity = 1 total_amount = '106.00' )
      ( order_no = 31 menu_item_id = 'CALABRESE' quantity = 1 total_amount = '43.40' )
      ( order_no = 32 menu_item_id = 'MARGHERITA' quantity = 1 total_amount = '39.80' )
      ( order_no = 33 menu_item_id = 'MARGHERITA' quantity = 1 total_amount = '41.40' )
      ( order_no = 34 menu_item_id = 'BACON_ONION' quantity = 1 total_amount = '49.40' )
      ( order_no = 35 menu_item_id = 'PEPPERONI_CHEDDAR' quantity = 1 total_amount = '58.20' )
      ( order_no = 36 menu_item_id = 'MARGHERITA' quantity = 1 total_amount = '39.00' )
      ( order_no = 37 menu_item_id = 'CALABRESE' quantity = 1 total_amount = '43.40' )
      ( order_no = 38 menu_item_id = 'MOZZARELLA' quantity = 1 total_amount = '35.00' )
      ( order_no = 38 menu_item_id = 'CALABRESE' quantity = 1 total_amount = '43.80' )
      ( order_no = 39 menu_item_id = 'MARGHERITA' quantity = 1 total_amount = '39.80' )
      ( order_no = 39 menu_item_id = 'QUATTRO_FORMAGGI' quantity = 1 total_amount = '51.00' )
      ( order_no = 40 menu_item_id = 'PEPPERONI_CHEDDAR' quantity = 2 total_amount = '108.80' )
      ( order_no = 41 menu_item_id = 'CALABRESE' quantity = 1 total_amount = '43.40' )
      ( order_no = 41 menu_item_id = 'COKE_CAN' quantity = 1 total_amount = '8.00' )
      ( order_no = 41 menu_item_id = 'HEINEKEN_473' quantity = 1 total_amount = '13.90' )
      ( order_no = 42 menu_item_id = 'MARGHERITA' quantity = 1 total_amount = '39.80' )
      ( order_no = 43 menu_item_id = 'MARGHERITA' quantity = 1 total_amount = '39.80' )
      ( order_no = 44 menu_item_id = 'PEPPERONI_CHEDDAR' quantity = 2 total_amount = '107.60' )
      ( order_no = 45 menu_item_id = 'PEPPERONI_CHEDDAR' quantity = 2 total_amount = '107.60' )
      ( order_no = 46 menu_item_id = 'MARGHERITA' quantity = 1 total_amount = '39.00' )
      ( order_no = 46 menu_item_id = 'GUARANA_CAN' quantity = 1 total_amount = '8.00' )
      ( order_no = 47 menu_item_id = 'CALABRESE' quantity = 1 total_amount = '43.40' )
      ( order_no = 48 menu_item_id = 'MOZZARELLA' quantity = 1 total_amount = '35.00' )
      ( order_no = 48 menu_item_id = 'CHICKEN_CATUPIRY' quantity = 1 total_amount = '49.80' )
      ( order_no = 49 menu_item_id = 'PEPPERONI_CHEDDAR' quantity = 1 total_amount = '58.20' )
      ( order_no = 50 menu_item_id = 'MARGHERITA' quantity = 1 total_amount = '39.80' )
      ( order_no = 51 menu_item_id = 'CALABRESE' quantity = 1 total_amount = '43.40' )
      ( order_no = 51 menu_item_id = 'COMBO_BACON_HAZELNUT' quantity = 1 total_amount = '106.00' )
      ( order_no = 52 menu_item_id = 'CALABRESE' quantity = 1 total_amount = '43.40' )
      ( order_no = 53 menu_item_id = 'CALABRESE' quantity = 1 total_amount = '43.40' )
      ( order_no = 54 menu_item_id = 'MARGHERITA' quantity = 1 total_amount = '39.80' )
      ( order_no = 54 menu_item_id = 'CALABRESE' quantity = 1 total_amount = '43.40' )
      ( order_no = 55 menu_item_id = 'CALABRESE' quantity = 1 total_amount = '43.40' )
      ( order_no = 56 menu_item_id = 'BACON_ONION' quantity = 1 total_amount = '49.40' )
      ( order_no = 56 menu_item_id = 'PEPPERONI' quantity = 1 total_amount = '48.80' )
      ( order_no = 57 menu_item_id = 'CALABRESE' quantity = 1 total_amount = '43.40' )
      ( order_no = 57 menu_item_id = 'BACON_ONION' quantity = 1 total_amount = '49.40' )
      ( order_no = 57 menu_item_id = 'HAZELNUT_NINHO' quantity = 1 total_amount = '31.20' )
      ( order_no = 58 menu_item_id = 'MOZZARELLA' quantity = 1 total_amount = '35.00' )
      ( order_no = 58 menu_item_id = 'BACON_ONION' quantity = 1 total_amount = '49.40' )
      ( order_no = 58 menu_item_id = 'HAZELNUT_NINHO' quantity = 1 total_amount = '31.20' )
      ( order_no = 59 menu_item_id = 'PEPPERONI' quantity = 1 total_amount = '48.80' )
      ( order_no = 60 menu_item_id = 'MARGHERITA' quantity = 1 total_amount = '39.80' )
      ( order_no = 61 menu_item_id = 'MARGHERITA' quantity = 1 total_amount = '39.80' )
      ( order_no = 62 menu_item_id = 'HAZELNUT_NINHO' quantity = 1 total_amount = '31.20' )
      ( order_no = 63 menu_item_id = 'CALABRESE' quantity = 1 total_amount = '43.40' )
      ( order_no = 63 menu_item_id = 'BACON_ONION' quantity = 1 total_amount = '49.40' )
      ( order_no = 63 menu_item_id = 'HEINEKEN_473' quantity = 1 total_amount = '13.90' )
      ).
  ENDMETHOD.

ENDCLASS.
