spool D:\Zinoviy\start\bad.txt
--Префиксы, заведённые в Форис
drop table rd_content;
create table rd_content as
select --+ ordered
distinct 
  pp.prefix
, pp.PHONE_PREFIX_NAME
, pg.PREFIX_GROUP_NAME 
, pgm.MEMBERSHIP_START
, pgm.MEMBERSHIP_END
, pp.MIN_LENGTH
, pp.MAX_LENGTH
from 
 rd.phone_prefix pp
, rd.prefix_group_member pgm
, (
 select * from rd.prefix_group
 where (PREFIX_GROUP_NAME like '%атегория%' or PREFIX_GROUP_NAME='SMS')
 and PREFIX_GROUP_NAME not like '%GOOD%OK%'
 and PREFIX_GROUP_NAME not like '%URL_%'
 and PREFIX_GROUP_NAME not like '%LBS%'
 and PREFIX_GROUP_NAME not like '%USSD%'
) pg
where 1=1
and pp.prefix not like '8107%'
and pp.prefix not like '801%'
and pp.prefix not like '+%'
and pp.prefix not like '74922%'
and pp.prefix not like '74932%'
and pp.prefix not like '74842%'
and pp.prefix not like '74942%'
and pp.prefix not like '74912%'
and pp.prefix not like '74812%'
and pp.prefix not like '74752%'
and pp.prefix not like '74822%'
and pp.prefix not like '74872%'
and pp.prefix not like '74852%'
and pp.prefix not in ('CC0384#562','.C0.139','D4#','MTS','MTS-Novosti','MTS-Tula','Vam_Zvonili','70957699100','74957699100','79106755555',
'89106755555','79168999100','79168999101','79168999102','LBS_Category_0')
and pp.PHONE_PREFIX_ID=pgm.PHONE_PREFIX_ID
and sysdate between pgm.membership_start and nvl(pgm.membership_end,sysdate)
and pgm.PREFIX_GROUP_ID=pg.PREFIX_GROUP_ID
order by PHONE_PREFIX_NAME;

commit;

alter table sdp_sms_content add direction varchar2(10); 

alter table rd_content add direction varchar2(10); 

--select * from rd.prefix_group
--select * from rd.phone_prefix
--select * from rd.prefix_group_member
--select * from rd_content order by 1
--select * from sdp_sms_content order by 1
--select * from rd_sms_content_price order by 1


--Приведём данные с SDP в удобоваримую форму

--delete sdp_sms_content where num_sdp not in (select short_num from katya.hp_ium@y.world h); -- Удаление номеров др. МР

update sdp_sms_content set direction = 'Исходящее'
where SDP_TARIFF_RULE in ('C0','C1','C4');
commit;

update sdp_sms_content set direction = 'Входящее'
where SDP_TARIFF_RULE in ('C2','C3','C5');
--and PRICE_SDP <> '0';
commit;

update rd_content set direction = 'Исходящее';
commit;

update rd_content set direction = 'Входящее'
where PREFIX_GROUP_NAME like '% - 0';
commit;

--Цены в Форис (ТП Базовый)
  --SMS Исходящее
drop table rd_sms_content_price;  
create table rd_sms_content_price as
select 
ltrim (tz.TARIFF_ZONE_NAME, 'МТС Москва --> ') as cat, 
rtrim(ltrim (p.PRICE_DESCRIPTION, 'Цена: '),'Цены для услуги:') as price,
p.time_schema_start
from 
rd.price        p, 
rd.TARIFF_ZONE tz 
where p.tariff_plan_id = 7000
and tz.TARIFF_ZONE_ID = p.TARIFF_ZONE_id 
and tz.TARIFF_ZONE_NAME like '%SMS%' ||'Категория%'
and p.NETWORK_SERVICE_ID in (3) --2 - Входящая SMS, 3 - Исходящая SMS
and TARIFF_ZONE_NAME like '%МТС Москва%' 
order by 1;

commit;

  --SMS Входящее
insert into rd_sms_content_price
select 
ltrim (tz.TARIFF_ZONE_NAME, 'МТС Москва <-- '), 
replace(rtrim(ltrim (p.PRICE_DESCRIPTION, 'Цена: '),'Цены для услуги:'),',','.'),
p.time_schema_start
from 
rd.price p,
rd.TARIFF_ZONE tz 
where p.tariff_plan_id = 7000
and tz.TARIFF_ZONE_ID = p.TARIFF_ZONE_id 
and tz.TARIFF_ZONE_NAME like '%SMS%' ||'категория%'
and p.NETWORK_SERVICE_ID in (2) --2 - Входящая SMS, 3 - Исходящая SMS
and TARIFF_ZONE_NAME like '%МТС Москва%'
order by 1;

commit;

  --MMS Исходящее
insert into rd_sms_content_price  
select 
ltrim (tz.TARIFF_ZONE_NAME, 'МТС Москва --> '), 
replace(ltrim (p.PRICE_DESCRIPTION, 'Цена: '),',','.'),
p.time_schema_start
from 
rd.price p
, rd.TARIFF_ZONE tz
where p.tariff_plan_id =7000 --in (385,6507,7000,7010,7930,7931,8121,8123)
and 
tz.TARIFF_ZONE_ID = p.TARIFF_ZONE_id 
and tz.TARIFF_ZONE_NAME like '%MMS%' ||'%атегория%'
and p.NETWORK_SERVICE_ID in (5) --2 - Входящая SMS, 3 - Исходящая SMS
and TARIFF_ZONE_NAME like '%МТС Москва%'
order by 1;

commit;

insert into rd_sms_content_price 
values ('SMS', 'по ТП', to_date('07.01.2007','dd.mm.yyyy') );
commit;
--select * from rd_sms_content_price

 --MMS Входящее
/*insert into rd_sms_content_price  
select 
ltrim (tz.TARIFF_ZONE_NAME, 'МТС Москва <-- '), 
ltrim (p.PRICE_DESCRIPTION, 'Цена: '),
p.time_schema_start
from 
rd.price p
, rd.TARIFF_ZONE tz 
where p.tariff_plan_id = 7000
and tz.TARIFF_ZONE_ID = p.TARIFF_ZONE_id 
and tz.TARIFF_ZONE_NAME like '%MMS%' ||'%атегория%'
and p.NETWORK_SERVICE_ID in (4) --2 - Входящая SMS, 3 - Исходящая SMS
and TARIFF_ZONE_NAME like '%МТС Москва%'
order by 1;

commit;*/

drop table rd_sms_content;
create table rd_sms_content as 
--truncate table rd_sms_content
select 
b.prefix
, b.phone_prefix_name
, b.prefix_group_name
, b.membership_start
, b.membership_end
, b.min_length
, b.max_length
,b.direction
,p.price
 from rd_sms_content_price p,
(select 
  rc.prefix
, rc.phone_prefix_name
, rc.prefix_group_name
, rc.membership_start
, rc.membership_end
, rc.min_length
, rc.max_length
,rc.direction,
--p.price,
max(p.time_schema_start) as time_schema_start
from 
rd_content            rc
,rd_sms_content_price p
where rc.prefix_group_name = p.cat 
group by rc.prefix, rc.phone_prefix_name, rc.prefix_group_name, rc.membership_start, rc.membership_end, rc.min_length, rc.max_length,rc.direction) b
where p.time_schema_start = b.TIME_SCHEMA_START
and p.cat = b.PREFIX_GROUP_NAME;

commit;
SPOOL OFF

--Подведём итоги
set echo off 
SET newpage 0 
SET space 0 
SET pagesize 0 
SET feed off 
SET head off 
SET trimspool ON
SET TERMOUT OFF
SET trimout ON 
SET linesize 4000

      --То, чего нет в Форис, но есть на SDP 
--truncate table net_v_foris;
--insert into net_v_foris
--select * from net_v_foris
drop table net_v_foris;
create table net_v_foris as
select 
s.NUM_SDP "Короткий номер"
,s.CAT_SDP "Тарифная категория"
,s.PRICE_SDP "Стоимость"
,s.direction "Направление тарификации"
,r.cat "Тарифная категория (РПУ)"
,r.price "Стоимость (РПУ)"
,r.direct "Направление тарификации (РПУ)"
,r.traffic "MAR/SDP"
,r.document "Документ"
from sdp_sms_content s, rpu r 
where NUM_SDP not in (select prefix from rd_content)
and r.num(+)=s.num_sdp
and num_sdp in (select short_num from katya.hp_ium@y.world h)
and num_sdp not like '801%'
 order by NUM_SDP;
 
grant select on net_v_foris to stat_msk; 

SPOOL D:\Zinoviy\net_v_foris.xls

select 
'АСР'||chr(9)||
'Короткий номер'||chr(9)||
'Тарифная категория'||chr(9)||
'Валюта'||chr(9)||
'Стоимость'||chr(9)||
'Направление тарификации'||chr(9)||
'Тарифная категория (РПУ)'||chr(9)||
'Стоимость (РПУ)'||chr(9)||
'Направление тарификации (РПУ)'||chr(9)||
'MAR/SDP'||chr(9)||
'Документ'||chr(9)
from dual;

select
'SDP'||chr(9)||
''''||"Короткий номер"||chr(9)||
"Тарифная категория"||chr(9)||
'Рубли'||chr(9)||
''''||"Стоимость"||chr(9)
||"Направление тарификации"||chr(9)
||"Тарифная категория (РПУ)"||chr(9)
||"Стоимость (РПУ)"||chr(9)
||"Направление тарификации (РПУ)"||chr(9)
||"MAR/SDP"||chr(9)
||"Документ"
from net_v_foris
order by "Короткий номер";

SPOOL OFF
      
--То, что есть в Форис, но нет на SDP 

--select * from net_na_sdp
--truncate table net_na_sdp;
--insert into net_na_sdp
drop table net_na_sdp;
create table net_na_sdp as
select 
rsc.PREFIX --"Короткий номер"
, replace (rsc.phone_prefix_name,'"') as phone_prefix_name --"Название префикса"
, rsc.PREFIX_GROUP_NAME               as PREFIX_GROUP_NAME --"Тарифная категория"
, rsc.PRICE                           as price             --"Стоимость"
, rsc.DIRECTION                       as DIRECTION         --"Направление тарификации"
, rsc.MEMBERSHIP_START                as MEMBERSHIP_START  --"Начало действия префикса"
, rsc.MEMBERSHIP_END                  as MEMBERSHIP_END    --"Завершение действия префикса"
, r.cat                               as cat               --"Тарифная категория (РПУ)"
,r.price                              as price_rpu         --"Стоимость (РПУ)"  
,r.direct                             as direct            --"Направление тарификации (РПУ)"
,r.traffic                                                 --"MAR/SDP"
,r.document                                                --"Документ"
from rd_sms_content rsc, rpu r  
where rsc.prefix not in (select NUM_SDP from sdp_sms_content) 
and sysdate between rsc.MEMBERSHIP_START and nvl (rsc.MEMBERSHIP_END, to_date('01-01-2018 00:00:00', 'dd-mm-yyyy hh24:mi:ss' ))
and r.num(+)=rsc.prefix
--and rsc.PREFIX_GROUP_NAME <> 'SMS'
;

grant select on net_na_sdp to stat_msk;

SPOOL D:\Zinoviy\net_na_sdp.xls

select 
'АСР'||chr(9)
||'Короткий номер'||chr(9)
||'Название префикса'||chr(9)
||'Тарифная категория'||chr(9)
||'Валюта'||chr(9)
||'Стоимость'||chr(9)
||'Направление тарификации'||chr(9)  
||'Дата начала действия префикса'||chr(9)
||'Дата завершения действия префикса'||chr(9)||
'Тарифная категория (РПУ)'||chr(9)||
'Стоимость (РПУ)'||chr(9)||
'Направление тарификации (РПУ)'||chr(9)||
'MAR/SDP'||chr(9)||
'Документ'||chr(9)
from dual;

select 
'Foris'||chr(9)
||''''||PREFIX||chr(9)
||PHONE_PREFIX_NAME||chr(9)
||PREFIX_GROUP_NAME||chr(9)
||'Рубли'||chr(9)
||''''||PRICE||chr(9)
||DIRECTION||chr(9)
||to_char(MEMBERSHIP_START, 'dd-mm-yyyy hh24:mi:ss' )||chr(9)
||to_char(MEMBERSHIP_END, 'dd-mm-yyyy hh24:mi:ss' )||chr(9)
||CAT||chr(9)
||PRICE_RPU||chr(9)
||DIRECT||chr(9)
||TRAFFIC||chr(9)
||DOCUMENT 
from net_na_sdp;  

SPOOL OFF

      --Несоответствие цены

drop table price_issues;
create table price_issues as
select distinct
(''''||PREFIX||chr(9)
||''''||NUM_SDP||chr(9)
||PHONE_PREFIX_NAME||chr(9)
||CAT_SDP||chr(9)
||PREFIX_GROUP_NAME||chr(9)
||''''||Price||chr (9)
||''''||PRICE_SDP||chr(9)
||SDP_TARIFF_RULE ||chr(9)
||''''||to_char(MEMBERSHIP_START, 'dd-mm-yyyy hh24:mi:ss' )||chr(9)
||''''||to_char(MEMBERSHIP_END, 'dd-mm-yyyy hh24:mi:ss' )||chr(9)
||''''||MIN_LENGTH||chr(9)
||''''||MAX_LENGTH ) as stolbets
from 
rd_sms_content r
, sdp_sms_content s
where 1=1
and r.prefix = s.num_sdp
and decode (Price,'по ТП','0.00')<> s.PRICE_SDP
--and r.prefix not in ()
;

SPOOL D:\Zinoviy\price_issues.xls

select 
'Префикс (Форис)'||chr(9)||
'Префикс (SDP)'||chr(9)||
'Название префикса (Форис)'||chr(9)||
'Категория (SDP)'||chr(9)||
'Название группы префиксов (Форис)'||chr(9)||
'Стоимость (Форис)'||chr(9)||
'Стоимость (SDP)'||chr(9)||
'Тип тарификации (SDP)'||chr(9)||
'Дата начала действия префикса (Форис)'||chr(9)||
'Дата завершения действия префикса (Форис)'||chr(9)||
'Минимальная длина префикса (Форис)'||chr(9)||
'Максимальная длина префикса (Форис)' from dual;

select distinct * from price_issues;

SPOOL OFF

insert into loshara --Технологическая таблица для вывода на сайт мониторинга
--create table loshara as
select 
sysdate "Дата",
(select count (*) from net_v_foris) "Нет в Форис",
(select count (*) from net_na_sdp) "Нет на SDP",
(select count (*) from price_issues) "Несоответствие в ценах",
(select count (*) from rd_sms_content r, sdp_sms_content s where r.prefix not in (select num from rpu) and r.prefix = s.num_sdp)
from  dual; 

commit;*/

DISCONNECT;
EXIT;

/*select * from sdp_sms_content --, rpu, rd_content
where num_sdp not in (select k.short_num from katya.hp_ium@y.world k)
and num_sdp = rpu.num
and PREFIX(+)=num_sdp
order by 1*/

--select * from sdp_sms_content where NUM_SDP = '1727'

/*select * from sdp_sms_content, rpu, katya.hp_ium@y.world k
where num_sdp not in (select PREFIX from rd_sms_content)
and num_sdp = rpu.num
and k.SHORT_NUM(+)=num_sdp
and k.SHORT_NUM<>num_sdp
order by 1*/


--and num_sdp in (select PREFIX from rd_sms_content)
     
--select rowid,l.* from loshara l 
--grant select on loshara to stat_msk;
--drop table rpu;
--create table rpu (num varchar2 (20) not null, cat varchar2 (125) not null, price varchar2 (20) not null, direct varchar2 (200) not null);

--select * from rpu order by 1

--delete loshara where DT = to_date('01.10.2007 11:36:28','dd-mm-yyyy hh24:mi:ss' )

--select * from rd.price

--drop database link y.world;
--create database link y.world
--connect to shchekutev identified by pokes254 using 'y'

--select * from katya.hp_ium@y.world  where SHORT_NUM in (3707,22288,0917) order by 1

--select * from rd_sms_content order by 1

--select r.*, rowid from rpu r  
--where NUM = 80200 
--order by 1

/*select -- +ordered
* from 
sdp_sms_content s
--, katya.hp_ium@y.world k
, rd_content r
, rpu
where 1=1
and num_sdp in (select k.short_num from katya.hp_ium@y.world k)

and s.num_sdp=r.prefix
and rpu.num(+) = num_sdp
order by 1*/ 

--select * from net_na_sdp

--
/*select 
r.PREFIX "Короткий номер"
, r.phone_prefix_name "Название префикса"
, r.PREFIX_GROUP_NAME "Тарифная категория"
, r.PRICE "Стоимость"
, r.DIRECTION "Направление тарификации"
 from rd_sms_content r, sdp_sms_content s where r.prefix not in (select num from rpu) and r.prefix = s.num_sdp
 

