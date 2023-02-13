---------------------------------------------------------------------------------
--
-- Filename      : customer_risk_td_risk.sql
-- Author        : Adam Regulinski
-- Date Created  : 4th OCT 2021
--
---------------------------------------------------------------------------------
--
-- Description   : Populate td tables that will populate the fact_risk table
--
-- Comments      : Initial Version
--
-- Usage         : GCP Big query
--
-- Called By     : customer_risk_fact.sh
--
-- Calls         : none.
--
-- Parameters    : n/a
--
-- Exit codes    : 0 - Success
--                 1 - Failure
--
-- Revisions
-- ====================================================================================
-- Date     userid  MR#            Comments                                      Ver.
-- ------   ------  -------------- --------------------------------------------  ------
-- 041021   ark08   Customer       Initial Version for GCP Big Query             1.0
-- 220222   acr73   INC2081555     Removing credit_agreement_refs from schema    1.1
-- 171022   pps08   FPS Replatform Updated FPS tables as per new structure       1.2    
---------------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- Collect data from source tables, joining out to verious source tables
-- and doing light transformations
----------------------------------------------------------------------------------
uk_pre_customer_risk_is.td_risk_p1:WRITE_TRUNCATE:
select rde.transactionid                               id,
       rde.createdate                                  created_dt,
       rde.createdbyuserid                             created_by_id,
       rde.modifieddate                                last_modified_dt,
       rde.modifiedbyuserid                            last_modified_by_id,
       case
         when upper(rde.order_type) = 'MOBILE' then
           co.partyid
         when upper(rde.order_type) = 'SOIP' then
           foe1.customerid
         else null
       end                                             party_id,
       case
         when upper(rde.order_type) = 'MOBILE' then
           ifnull(cpe.serviceinstanceid, pp.serviceinstanceid)
         when upper(rde.order_type) = 'SOIP' then
           ser2.id
         else null
       end                                             service_instance_id,
       case
         when upper(rde.order_type) = 'MOBILE' then
           cast(ciam.account_no as string)
         when upper(rde.order_type) = 'SOIP' then
           foe2.accountnumber
         else null        
       end                                             account_number,
       case
         when upper(rde.order_type) = 'MOBILE' then
           ba1.id
         when upper(rde.order_type) = 'SOIP' then
           foe2.id
         else null
       end                                             billing_account_id,
       row_number() over (partition by rde.transactionid,
                                       ppc.account_no
                              order by ppc.create_dt desc,
                                       cpe.created   desc) row_num
  from uk_tds_mi_eod_is.cc_mi_rol_dataextract rde
  left join uk_tds_ordermanagement_eod_is.cc_ordermanagement_om_co_risk_assessment cra
    on cast(rde.transactionid as string) = cra.inter_connect_transaction_id
   and rde.order_id                      = cra.customer_order_id
  left join uk_tds_ordermanagement_eod_is.cc_ordermanagement_om_customer_order co
    on cra.customer_order_id = co.customer_order_id
  left join (select ord1.orderid,
                    ord1.customerid,
                    ser1,
                    row_number() over (partition by ord1.orderid,
                                                    ord1.customerid
                                           order by s1.created desc) rn1
               from uk_tds_customer_fulfilment_eod_is.cc_customer_fulfilment_order_event_orders ord1
              inner join uk_tds_customer_fulfilment_eod_is.cc_customer_fulfilment_order_event_services ser1
                 on ord1.orderid          = ser1.orderid     
              inner join uk_tds_chordiant_eod_is.cc_chordiant_service s1
                 on ser1.id               = s1.id
                and upper(s1.servicetype) = 'SOIP'
                and s1.logically_deleted  = 0) foe1
    on rde.order_id = foe1.orderid
   and foe1.rn1     = 1
  left join (select ord2.orderid,
                    ord2.customerid,
                    ser2,
                    acc2,
                    ba.accountnumber,
                    ba.id,
                    row_number() over (partition by ord2.orderid,
                                                    ord2.customerid
                                           order by s2.created desc) rn2
               from uk_tds_customer_fulfilment_eod_is.cc_customer_fulfilment_order_event_orders ord2, 
                    unnest(ord2.accounts) as acc2
              inner join uk_tds_customer_fulfilment_eod_is.cc_customer_fulfilment_order_event_services ser2
                 on ord2.orderid          = ser2.orderid 
              inner join uk_tds_chordiant_eod_is.cc_chordiant_service s2
                 on ser2.id               = s2.id
                and upper(s2.servicetype) = 'SOIP'
                and s2.logically_deleted  = 0
              inner join uk_tds_chordiant_eod_is.cc_chordiant_bsbbillingaccount ba
                 on s2.billingserviceinstanceid = ba.serviceinstanceid
                and ba.logically_deleted        = 0) foe2
    on rde.order_id = foe2.orderid
   and foe2.rn2 = 1
  left join uk_tds_kenan_eod_is.cc_kenan_est_customer_id_acct_map ciam
    on co.accountnumber       = ciam.external_id
   and ciam.external_id_type  = 1
   and ciam.logically_deleted = 0
  left join uk_tds_kenan_eod_is.cc_kenan_extn_payment_plan_contract ppc
    on ciam.account_no       = ppc.account_no
   and ppc.logically_deleted = 0
  left join uk_tds_chordiant_eod_is.cc_chordiant_bsbpriceableunitportfolioprod ppp
    on ppc.priceable_unit_id = ppp.priceableunitid
   and ppp.logically_deleted = 0
  left join uk_tds_chordiant_eod_is.cc_chordiant_bsbportfolioproduct pp
    on ppp.portfolioproductid = pp.id
   and pp.logically_deleted   = 0
  left join uk_tds_chordiant_eod_is.cc_chordiant_bsbcustomerproductelement cpe
    on pp.id                 = cpe.portfolioproductid
   and cpe.logically_deleted = 0
  left join uk_tds_chordiant_eod_is.cc_chordiant_bsbbillingaccount ba1
    on ciam.external_id      = ba1.accountnumber
   and ba1.logically_deleted = 0;

----------------------------------------------------------------------------------
-- Remove dups and select clostest portfolio product ie - record with the least 
-- difference between the created in bsbcustomerproductelement and create_dt 
-- in extn_payment_plan_contract
----------------------------------------------------------------------------------
uk_pre_customer_risk_is.td_risk:WRITE_TRUNCATE:
select id,
       created_dt,
       created_by_id,
       last_modified_dt,
       last_modified_by_id,
       party_id,
       service_instance_id,
       account_number,
       billing_account_id
  from uk_pre_customer_risk_is.td_risk_p1
 where row_num = 1;
 