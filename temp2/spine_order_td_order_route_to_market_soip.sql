--------------------------------------------------------------------------------
--
-- Filename      : spine_order_td_order_route_to_market_soip.sql
-- Author        : Stuart Glasgow
-- Date Created  : 10th Aug 2021
--
--------------------------------------------------------------------------------
--
-- Description   : Populate transient tables with SoIP data required to populate
--                 dimension table DIM_ORDER_ROUTE_TO_MARKET
--
-- Comments      : Lists the route to market for each order
--
-- Usage         : Standard BQSQL Call
--
-- Called By     : spine_order_mart.sh
--
-- Calls         : none
--
-- Parameters    : 1) lower_date_bound - DD-MON-YYYY HH24:MI:SS
--                 2) upper_date_bound - DD-MON-YYYY HH24:MI:SS.SSSSS
--
-- Exit codes    : 0 - Success
--                 1 - Failure
--
-- Revisions
-- ================================================================================
-- Date    Userid  MR#            Comments                                     Ver.
-- ------  ------  ----------     -------------------------------------------  ----
-- 100821  SGW01   Soip           Initial Version                              1.0
-- 200821  SGW01   Soip           Added default values                         1.1
-- 260821  SGW01   Soip           Used left joins where required               1.2
-- 071021  GAJ07   SCW-1121       Changes to rtm_level_1, 2 & 3 mapping        1.3
-- 121121  SGW01   SOIP           Bugfix for duplication - SCW-1327            1.4
-- 011122  PPS08   FPS Replatform Updated FPS tables as per new structure      1.5
----------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
-- Get all SoIP related data required for calculating different levels
--------------------------------------------------------------------------------
uk_pre_cust_spine_order_is.td_order_route_to_market_soip_p1:WRITE_TRUNCATE:
select  oe.orderid,
        timestamp(datetime(timestamp(oe.orderCreatedDateTime),'Europe/London')) orderCreatedDateTime,
        sb.rtmlevel1,
        sb.rtmlevel2,
        sb.rtmlevel3,       
        inf.name,
        inf.created,
        inf.deleted,
        row_number() over (partition by oe.orderid
                               order by inf.created desc) row_num
  from uk_tds_customer_fulfilment_eod_is.cc_customer_fulfilment_order_event_orders oe
 inner join uk_tds_customer_fulfilment_eod_is.cc_customer_fulfilment_order_event_services services
    on (    oe.orderid           = services.orderid)
 inner join uk_tds_chordiant_eod_is.cc_chordiant_service cs
    on (    cs.id                = services.id
        and cs.logically_deleted = 0)
  left join uk_tds_oneshop_eod_is.cc_oneshop_sb_spsinteraction si
    on (    oe.orderid           = si.orderid
        and si.logically_deleted = 0)
  left join uk_tds_oneshop_eod_is.cc_oneshop_sb_spssalesbasket sb
    on (    sb.id = si.salesbasketid
        and sb.logically_deleted = 0)
  left join (select ga.created,
                    ifnull(ga.deleted, '2999-12-31 23:59:59') deleted,
                    gp.name,
                    ag.username
               from uk_tds_infomart_eod_is.cc_infomart_gidb_gcx_group_agent ga
              inner join uk_tds_infomart_eod_is.cc_infomart_gidb_gc_agent ag
                 on (              ga.agentid = ag.id
                     and ag.logically_deleted = 0)
              inner join uk_tds_infomart_eod_is.cc_infomart_gidb_gc_group gp
                 on (              ga.groupid = gp.id
                     and gp.logically_deleted = 0
                     and              gp.name like 'SKG%')
              where ga.logically_deleted = 0
            ) inf
    on (    oe.agentid              =  inf.username
        and timestamp(datetime(timestamp(oe.ordercreateddatetime),'Europe/London'))  >= inf.created
        and timestamp(datetime(timestamp(oe.ordercreateddatetime),'Europe/London'))  <  inf.deleted);

--------------------------------------------------------------------------------
-- Calculate rtm_level_1, rtm_level_2 & rtm_level_3 and filter out 
-- everything which is not the most recent record (row_num 1) for each order_id
--------------------------------------------------------------------------------
uk_pre_cust_spine_order_is.td_order_route_to_market_soip:WRITE_TRUNCATE:
select p1.orderid                            order_id,
       ifnull(p1.rtmlevel1, 'Direct')        rtm_level_1,
       case
         when upper(p1.rtmlevel2) <> 'UNKNOWN' then
           p1.rtmlevel2
         when upper(p1.rtmlevel2) = 'UNKNOWN' then
           case
             when (   upper(p1.name) like '%SAVE%'
                   or upper(p1.name) like '%RETENTION%'
                   or upper(p1.name) like '%WINBACK%'
                   or upper(p1.name) like '%CHURN%') then
               'Direct Save'
             when (   upper(p1.name) like '%SELL%'
                   or upper(p1.name) like '%SALE%') then
               'Direct Sell'
             when p1.name is not null then
               'Direct Serve'
             else
               'Direct Other'
           end
         else
           'Direct Other'
       end                                   rtm_level_2,
       case
         when upper(p1.rtmlevel3) not like 'UNKNOWN%' then
           p1.rtmlevel3
         when upper(p1.rtmlevel3) = 'UNKNOWN INBOUND' then
           case
             when (   upper(p1.name) like '%SAVE%'
                   or upper(p1.name) like '%RETENTION%'
                   or upper(p1.name) like '%WINBACK%'
                   or upper(p1.name) like '%CHURN%') then
               'Direct Save Inbound'
             when (   upper(p1.name) like '%SELL%'
                   or upper(p1.name) like '%SALE%') then
               'Direct Sell Inbound'
             when p1.name is not null then
               'Direct Serve Inbound'
             else
               'Direct Other'
           end
         when upper(p1.rtmlevel3) = 'UNKNOWN OUTBOUND' then
           case
             when (   upper(p1.name) like '%SAVE%'
                   or upper(p1.name) like '%RETENTION%'
                   or upper(p1.name) like '%WINBACK%'
                   or upper(p1.name) like '%CHURN%') then
               'Direct Save Outbound'
             when (   upper(p1.name) like '%SELL%'
                   or upper(p1.name) like '%SALE%') then
               'Direct Sell Outbound'
             when p1.name is not null then
               'Direct Serve Outbound'
             else
               'Direct Other'
           end
         when upper(p1.rtmlevel3) = 'UNKNOWN OTHER' then
           case
             when (   upper(p1.name) like '%SAVE%'
                   or upper(p1.name) like '%RETENTION%'
                   or upper(p1.name) like '%WINBACK%'
                   or upper(p1.name) like '%CHURN%') then
               'Direct Save Other'
             when (   upper(p1.name) like '%SELL%'
                   or upper(p1.name) like '%SALE%') then
               'Direct Sell Other'
             when p1.name is not null then
               'Direct Serve Other'
             else
               'Direct Other'
           end
         else
           'Direct Other'
       end                                   rtm_level_3
  from uk_pre_cust_spine_order_is.td_order_route_to_market_soip_p1 p1
 where p1.row_num = 1;
 