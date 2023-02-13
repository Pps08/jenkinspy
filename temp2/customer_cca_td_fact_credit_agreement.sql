--------------------------------------------------------------------------------
--
-- Filename      : customer_cca_td_fact_credit_agreement.sql
-- Author        : Alokendu Pal
-- Date Created  : 09th jun 2021
--
--------------------------------------------------------------------------------
--
-- Description   : Truncate and repopulate the td_fact_credit_agreement_p1 table
--                 as a precursor to loading td_fact_credit_agreement
--
-- Comments      : NA
--
-- Usage         : Standard BQSQL Call
--
-- Called By     : customer_cca_fact.sh
--
-- Calls         : none.
--
-- Exit codes    : 0 - Success
--                 1 - Failure
--
-- Revisions
-- ==================================================================================
-- Date     userid  MR#            Comments                                      Ver.
-- ------   ------  -------------- --------------------------------------------  ----
-- 060321    app03  spine          initial version                               1.0
-- 160222    acr73  INC2081555     Introducing tranaction_id and refactoring 
--                                 service_instance_id and product_id            1.1
-- 160522    siv03  BDCF-2218      adding additional columns                     
-- 070622    ary17  INC2195698     fix                                           1.2
-- 171022    pps08  FPS Replatform Updated FPS tables as per new structure       1.3
------------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- create td_fact_credit_agreement extracting all data from the relevant source tables.
--------------------------------------------------------------------------------
uk_pre_customer_cca_is.td_fact_credit_agreement_p1:WRITE_TRUNCATE:
select ppc.agreement_ref,
       ppc.create_dt,
       ppc.create_usr,
       ppc.update_dt,
       ppc.update_usr,
       ppc.account_no,
       ppc.priceable_unit_id,
       ppc.plan_type,
       ppc.plan_repayments,
       ppc.activation_date,
       ppc.activation_offset_days,
       ppc.contract_signed_date,
       ppc.signing_expiry_date,
       ppc.closed_date,
       cast(ppc.type_id_nrc as string) as type_id_nrc,
       ppc.plan_value,
       ppc.total_value,
       ppc.discount_value,
       ppc.prepaid_value,
       ppc.delta_value,
       ppc.affordability_value,
       ppc.proposition_value,
       ppc.cash_price,
       case 
         when pp.id is not null then 
            pp.serviceinstanceid
         when ppil.pricingitemid is not null then 
            p.serviceid
       end                          serviceinstanceid,
       case 
         when cpe.id is not null then 
            cpe.id
         when pilink.id is not null then 
            to_base64(sha512(concat(pilink.id,':',
                                    p.id,':',
                                    p.serviceid)))
       end                          product_id,
       row_number() over (partition by ppc.agreement_ref
                          order by abs(timestamp_diff(pp.created,ppc.create_dt,second))) as pp_index,
       row_number() over (partition by ppc.agreement_ref
                          order by abs(timestamp_diff(cpe.created,ppc.create_dt,second))) as cpp_index
  from uk_tds_kenan_eod_is.cc_kenan_extn_payment_plan_contract ppc
  left join uk_tds_chordiant_eod_is.cc_chordiant_bsbpriceableunitportfolioprod pupp
    on ppc.priceable_unit_id = pupp.priceableunitid
  left join uk_tds_chordiant_eod_is.cc_chordiant_bsbportfolioproduct pp
    on pupp.portfolioproductid = pp.id
  left join uk_tds_chordiant_eod_is.cc_chordiant_bsbcustomerproductelement cpe
    on pp.id = cpe.portfolioproductid
   and pupp.portfolioproductid = cpe.portfolioproductid
  left join uk_tds_chordiant_eod_is.cc_chordiant_productpricingitemlink ppil
    on ppc.priceable_unit_id = ppil.pricingitemid
  left join uk_tds_chordiant_eod_is.cc_chordiant_product p
    on ppil.productid = p.id
  left join (select ppl.productid,
                    prc.id
              from uk_tds_chordiant_eod_is.cc_chordiant_productpricingitemlink ppl
             inner join uk_tds_chordiant_eod_is.cc_chordiant_pricingitem prc
                on (    prc.id = ppl.pricingitemid
                    and prc.logically_deleted = 0
                    and upper(prc.chargetypecode)='NRC')
              where ppl.logically_deleted = 0) pilink
   on pilink.productid=p.id;
--------------------------------------------------------------------------------
-- Filter out all records and calculate required values
--------------------------------------------------------------------------------
uk_pre_customer_cca_is.td_fact_credit_agreement_p2:WRITE_TRUNCATE:
select p1.agreement_ref                                    agreement_ref,
       p1.create_dt                                        created_dt,
       p1.create_usr                                       created_by_id,
       p1.update_dt                                        last_modified_dt,
       p1.update_usr                                       last_modified_by_id,
       pr.partyid                                          party_id,
       ba.portfolioid                                      portfolio_id,
       ba.id                                               billing_account_id,
       map.external_id                                     account_number,
       p1_1.serviceinstanceid                              service_instance_id,
       p1_1.product_id                                     product_id,
       p1.priceable_unit_id                                priceable_unit_id ,
       p1.plan_type                                        plan_type,
       p1.plan_repayments                                  number_of_repayments,
       p1.activation_date                                  activation_date,
       p1.activation_offset_days                           activation_offset_days,
       p1.contract_signed_date                             contract_signed_date,
       p1.signing_expiry_date                              signing_expiry_dt,
       p1.closed_date                                      closed_dt,
       cast(p1.type_id_nrc as string)                      catalogue_product_id,
       cp.productname                                      catalogue_product_name,
       cp.productbillname                                  catalogue_product_bill_name,
       cp.productdescription                               catalogue_product_description,
       substr(cpt.description,4)                           catalogue_product_type,
       cp.product_type                                     catalogue_product_transaction_type_code,
       p1.plan_value/100                                   plan_value,
       p1.total_value/100                                  total_value,
       p1.discount_value/100                               discount_value,
       p1.prepaid_value/100                                prepaid_value,
       p1.delta_value/100                                  delta_value,
       p1.affordability_value/100                          affordability_value,
       p1.proposition_value/100                            proposition_value,
       p1.cash_price/100                                   cash_price
  from uk_tds_kenan_eod_is.cc_kenan_extn_payment_plan_contract p1
  left join uk_tds_refdata_eod_is.cc_refdata_bsbcatalogueproduct cp
    on cast(p1.type_id_nrc as string) = cp.id
   and cp.rdmdeletedflag = 'N'
  left join uk_tds_refdata_eod_is.cc_refdata_bsbproducttoproducttype ptpt
    on cp.id = ptpt.catalogueproductid
   and ptpt.rdmdeletedflag = 'N'
  left join uk_tds_refdata_eod_is.cc_refdata_bsbcatalogueproducttype cpt
    on ptpt.catalogueproducttypeid = cpt.id
   and cpt.rdmdeletedflag = 'N'
 inner join uk_tds_kenan_eod_is.cc_kenan_est_customer_id_acct_map map
    on p1.account_no        = map.account_no 
   and map.external_id_type = 1
   and map.logically_deleted = 0
 inner join uk_tds_chordiant_eod_is.cc_chordiant_bsbbillingaccount ba
    on map.external_id      = ba.accountnumber 
   and map.external_id_type = 1
   and ba.logically_deleted = 0
 inner join uk_tds_chordiant_eod_is.cc_chordiant_bsbcustomerrole cr 
    on ba.portfolioid = cr.portfolioid
 inner join uk_tds_chordiant_eod_is.cc_chordiant_bsbpartyrole pr
    on cr.partyroleid = pr.id
 inner join uk_pre_customer_cca_is.td_fact_credit_agreement_p1 p1_1 
    on p1.agreement_ref = p1_1.agreement_ref
 where ifnull(cpt.description,'WH_') like 'WH_%'
   and ifnull(map.is_current,1) = 1
   and ifnull(p1_1.pp_index,1)  = 1 
   and ifnull(p1_1.cpp_index,1) = 1
   and p1.logically_deleted = 0;
 
----------------------------------------------------------------------------
-- Write_truncate final td table and bring in transaction_id
----------------------------------------------------------------------------
uk_pre_customer_cca_is.td_fact_credit_agreement:WRITE_TRUNCATE:
select p2.agreement_ref,
       case 
         when cra.inter_connect_transaction_id is not null then 
           cast(cra.inter_connect_transaction_id as int)
         when rol.transactionid is not null then 
           cast(rol.transactionid as int)
       end                                                 transaction_id,
       p2.created_dt,
       p2.created_by_id,
       p2.last_modified_dt,
       p2.last_modified_by_id,
       p2.party_id,
       p2.portfolio_id,
       p2.billing_account_id,
       p2.account_number,
       p2.service_instance_id,
       p2.product_id,
       p2.priceable_unit_id,
       p2.plan_type,
       p2.number_of_repayments,
       p2.activation_date,
       p2.activation_offset_days,
       p2.contract_signed_date,
       p2.signing_expiry_dt,
       p2.closed_dt,
       p2.catalogue_product_id,
       p2.catalogue_product_name,
       p2.catalogue_product_bill_name,
       p2.catalogue_product_description,
       p2.catalogue_product_type,
       p2.catalogue_product_transaction_type_code,
       p2.plan_value,
       p2.total_value,
       p2.discount_value,
       p2.prepaid_value,
       p2.delta_value,
       p2.affordability_value,
       p2.proposition_value,
       p2.cash_price
  from uk_pre_customer_cca_is.td_fact_credit_agreement_p2 p2
  left join uk_tds_ordermanagement_eod_is.cc_ordermanagement_om_co_payment_plan cpp
    on cpp.agreement_number = p2.agreement_ref
   and cpp.activation_date  = p2.activation_date
   and lower(cpp.signed)    = 'true'
   and upper(cpp.state)     = 'ACTIVATED'
  left join uk_tds_ordermanagement_eod_is.cc_ordermanagement_om_co_risk_assessment cra
    on cra.customer_order_id = cpp.customer_order_id
   and contains_substr(cra.a_indicator, 'NO_FRAUD')
  left join ( select o.orderID, 
                     sv.id service_id, 
                     sv.action service_action,
                     ca.action credit_ag_action,
                     ca.agreementNumber
                from uk_tds_customer_fulfilment_eod_is.cc_customer_fulfilment_order_event_orders o,
                     unnest(creditAgreements) ca
               inner join uk_tds_customer_fulfilment_eod_is.cc_customer_fulfilment_order_event_services sv
                       on o.orderid = sv.orderid ) oe
    on oe.agreementNumber           = p2.agreement_ref
   and upper(oe.credit_ag_action)   = 'ADD'
   and oe.service_id                = p2.service_instance_id
   and upper(oe.service_action)     = 'ADD'
  left join uk_tds_mi_eod_is.cc_mi_rol_dataextract rol
    on rol.order_id   = oe.orderID
   and rol.ORDER_LINE = 1;
 