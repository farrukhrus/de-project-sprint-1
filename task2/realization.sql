create or replace view analysis.orders_v as (
	select  o.order_id, 
			o.order_ts, 
			o.user_id, 
			o.bonus_payment, 
			o.payment , 
			o."cost" ,
			o.bonus_grant, 
			os.status_id as status
	from production.orders o 
	inner join (select order_id, status_id, max(dttm) as max_date 
				from production.orderstatuslog group by order_id, status_id) os 
	on o.order_id = os.order_id
);