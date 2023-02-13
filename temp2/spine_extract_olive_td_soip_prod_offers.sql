--------------------------------------------------------------------------------
--
-- Filename      : spine_extract_olive_td_soip_prod_offers.sql
-- Author        : Will Allen
-- Date Created  : 22nd June 2021
--
--------------------------------------------------------------------------------
--
-- Description   : SOIP Olive GCP: SOIP_PROD_OFFERS
--
-- Comments      : NA
--
-- Usage         : Standard BQSQL Call
--
-- Called By     : spine_extract_olive_soip_daily.sh
--
-- Calls         : none.
--
-- Parameters    : none
--
-- Exit codes    : 0 - Success
--                 1 - Failure
--
-- Revisions
-- ==================================================================================
-- Date     userid  MR#            Comments                                      Ver.
-- ------   ------  -------------- --------------------------------------------  ----
-- 220621   wa91                   Initial version                               1.0
-- 101121   sgw01                  Fix for duplicate rates issue by creating     1.1
--                                 lookup from foe and using catalogue_version   
--                                 in joins
-- 231221   mke75  scw-1596        Renaming table soip_prod_offers to 
--                                 td_soip_prod_offers and changing script name 
--                                 and casting columns                           1.2
-- 120122   mke75   BDG-1490       Bug fix for lkp table                         1.3
-- 111022   pps08   FPS Replatform Updated FPS tables as per new structure       1.4
-------------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- STEP 0: create lookup table
--------------------------------------------------------------------------------
uk_tmp_cust_spine_extracts_is.td_soip_prod_offers_lkp:WRITE_TRUNCATE:
select id                                                                   product_id,
       orderid                                                              order_id,
       timestamp(datetime(timestamp(orderCreatedDateTime),'Europe/London')) order_created_dt,
       catalogueversion                                                     catalogue_version,
       row_number() over (partition by id 
                              order by timestamp(datetime(timestamp(orderCreatedDateTime),'Europe/London')) ) row_num
  from uk_tds_customer_fulfilment_eod_is.cc_customer_fulfilment_order_event_products ;

--------------------------------------------------------------------------------
-- STEP I: extracts all data from source tables
--------------------------------------------------------------------------------
uk_tmp_cust_spine_extracts_is.td_soip_prod_offers_p1:WRITE_TRUNCATE:
select p.id                                                            product_id,
       bba.id                                                          billing_account_id,
       oh.offerid                                                      offer_id,
       oh.suid                                                         offer_suid,
       oh.id                                                           offer_hist_id,
       case                                                            
         when oh.csn = -1 then                                         
           oh.created                                                  
         else                                                          
           oh.commit_ts                                                
       end                                                             offer_effective_from_dt,
       oh.csn                                                          effective_from_dt_csn_seq,
       oh.audit_pos                                                    effective_from_dt_seq,
       cast(null as timestamp)                                         offer_effective_to_dt,
       dpi.id                                                          discount_id,
       dpi.rateid                                                      discount_rate_id,
       pi.id                                                           price_id,
       pi.rateid                                                       price_rate_id,
       round(rp.price/100,2)                                           product_price,
       bba.currencycode                                                currency
 from  uk_tds_chordiant_eod_is.cc_chordiant_product p
 inner join uk_tds_chordiant_eod_is.cc_chordiant_service s
    on (    p.serviceid                 = s.id
        and s.logically_deleted         = 0)
 inner join uk_tds_chordiant_eod_is.cc_chordiant_bsbbillingaccount bba
    on (    s.billingserviceinstanceid  = bba.serviceinstanceid
       and  s.servicetype               = 'SOIP'
       and  bba.logically_deleted       = 0)
 inner join uk_tds_chordiant_eod_is.cc_chordiant_productpricingitemlink ppil
    on (    p.id                        = ppil.productid
        and ppil.logically_deleted      = 0)
 inner join uk_tmp_cust_spine_extracts_is.td_soip_prod_offers_lkp lkp
    on (    ppil.productid              = lkp.product_id
        and lkp.row_num                 = 1)
  left join uk_tds_chordiant_eod_is.cc_chordiant_pricingitem pi
    on (    ppil.pricingitemid          = pi.id
        and pi.logically_deleted        = 0)
 inner join uk_tds_chordiant_eod_is.cc_chordiant_discountpricingitemlink dpil
    on (    pi.id                       = dpil.pricingitemid
        and dpil.logically_deleted      = 0)
 inner join uk_tds_chordiant_eod_is.cc_chordiant_discountpricingitem dpi
    on (    dpil.discountpricingitem    = dpi.id
        and dpi.logically_deleted       = 0)
 inner join uk_tds_chordiant_eod_is.cc_chordiant_offer o
    on (    dpi.offerid                 = o.id
        and o.logically_deleted         = 0)
 inner join uk_tds_chordiant_eod_is.cc_chordiant_offerhistory oh
    on (    o.id                        = oh.offerid
        and oh.logically_deleted        = 0)
  left join uk_tds_xds_eod_is.cc_xds_rates r
    on (    pi.rateid                   = r.rate_id
        and r.catalogue_version         = lkp.catalogue_version
        and lkp.row_num                 = 1)
  left join uk_tds_xds_eod_is.cc_xds_rates_pricing rp
    on (    rp.suid                     = r.suid
        and rp.currency                 = bba.currencycode
        and rp.catalogue_version        = lkp.catalogue_version
        and lkp.row_num                 = 1)
 where p.logically_deleted = 0;

--------------------------------------------------------------------------------
-- Get records from p1, and apply lag function
--------------------------------------------------------------------------------
uk_tmp_cust_spine_extracts_is.td_soip_prod_offers:WRITE_TRUNCATE:
 select
    current_timestamp()                                                dw_last_modified_dt,
    cast(product_id as string)                                         product_id,
    cast(billing_account_id as string)                                 billing_account_id,
    cast(offer_id as string)                                           offer_id,
    cast(offer_suid as string)                                         offer_suid,
    cast(offer_hist_id as string)                                      offer_hist_id,
    cast(offer_effective_from_dt as timestamp)                         offer_effective_from_dt,
    lag(offer_effective_from_dt, 1, timestamp('2999-12-31 23:59:59'))  
        over(partition by offer_id                                     
                 order by offer_effective_from_dt   desc,              
                          effective_from_dt_csn_seq desc,              
                          effective_from_dt_seq     desc               
            )                                                          offer_effective_to_dt,
    cast(discount_id as string)                                        discount_id,
    cast(discount_rate_id as integer)                                  discount_rate_id,
    cast(price_id as string)                                           price_id,
    cast(price_rate_id as integer)                                     price_rate_id,
    cast(product_price as numeric)                                     product_price,
    cast(currency as string)                                           currency
 from uk_tmp_cust_spine_extracts_is.td_soip_prod_offers_p1;
   