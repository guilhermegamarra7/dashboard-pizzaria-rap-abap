CLASS zcl_pz_hello DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_pz_hello IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
  out->write( |Olá, pizzaria! Hoje é { cl_abap_context_info=>get_system_date( ) DATE = USER }| ).
  ENDMETHOD.
ENDCLASS.
