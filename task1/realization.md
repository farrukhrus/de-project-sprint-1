# Витрина RFM

## 1.1. Выясните требования к целевой витрине.

Постановка задачи выглядит достаточно абстрактно - постройте витрину. Первым делом вам необходимо выяснить у заказчика детали. Запросите недостающую информацию у заказчика в чате.

Зафиксируйте выясненные требования. Составьте документацию готовящейся витрины на основе заданных вами вопросов, добавив все необходимые детали.

-----------

Требуется построить витрину для RFM-классификации. Для анализа нужно отобрать только успешно выполненные заказы. Не требуется обновление данных. Витрина должна находиться в схеме analytics.
Название витрины: dm_rfm_segments
Необходимая структура:
- user_id - id клиента;
- recency - Фактор Recency (число от 1 до 5);
- frequency - Фактор Frequency (число от 1 до 5);
- monetary_value - Фактор Monetary Value (число от 1 до 5).



## 1.2. Изучите структуру исходных данных.

Полключитесь к базе данных и изучите структуру таблиц.

Если появились вопросы по устройству источника, задайте их в чате.

Зафиксируйте, какие поля вы будете использовать для расчета витрины.

-----------
таблица orders:
- user_id - as is;
- recency - строится на основе поля order_ts;
- frequency - строится на основе поля order_id;
- monetary_value - строится на основе поля payment.

таблица orderstatuses:
Справочник. Связана с таблицей orders и используется для фильтрации успешно выполненных заказов (с статусом Closed)


## 1.3. Проанализируйте качество данных

Изучите качество входных данных. Опишите, насколько качественные данные хранятся в источнике. Так же укажите, какие инструменты обеспечения качества данных были использованы в таблицах в схеме production.

-----------

В таблице orders отсутствуют дубли и NULL значения по ключевому полю order_id. 
В таблице orderstatuses имеет только уникальные значения в ключевом поле id;

Ограниченичители. 
orders:
- Ограничение первичного ключа по полю order_id;
- Ограничение-проверка cost = (payment + bonus_payment);
orderstatuses:
- Ограничение первичного ключа по полю id;


## 1.4. Подготовьте витрину данных

Теперь, когда требования понятны, а исходные данные изучены, можно приступить к реализации.

### 1.4.1. Сделайте VIEW для таблиц из базы production.**

Вас просят при расчете витрины обращаться только к объектам из схемы analysis. Чтобы не дублировать данные (данные находятся в этой же базе), вы решаете сделать view. Таким образом, View будут находиться в схеме analysis и вычитывать данные из схемы production. 

Напишите SQL-запросы для создания пяти VIEW (по одному на каждую таблицу) и выполните их. Для проверки предоставьте код создания VIEW.

```SQL
create or replace view analysis.users_v as (select * from production.users);
create or replace view analysis.products_v as (select * from production.products);
create or replace view analysis.orderitems_v as (select * from production.orderitems);
create or replace view analysis.orders_v as (select * from production.orders);
create or replace view analysis.orderstatuslog_v as (select * from production.orderstatuslog);
create or replace view analysis.orderstatuses_v as (select * from production.orderstatuses);
--or 
create or replace view analysis.dm_rfm_segments_v as (
	select user_id, 
	       ntile(5) over (order by last_order_dt) as recency,
	       ntile(5) over (order by order_count) as frequency,
	       ntile(5) over (order by order_sum) as monetary_value
	from (
		select user_id, 
			   max(order_ts) as last_order_dt,
			   count(distinct order_id) as order_count,
			   sum(payment) as order_sum
		from production.orders o inner join production.orderstatuses os on o.status = os.id
		where os."key" = 'Closed'
	group by user_id) t1 
)
```

### 1.4.2. Напишите DDL-запрос для создания витрины.**

Далее вам необходимо создать витрину. Напишите CREATE TABLE запрос и выполните его на предоставленной базе данных в схеме analysis.

```SQL
create table analysis.dm_rfm_segments
(
	user_id int primary key,
	recency int not null check (recency between 0 and 5),
	frequency int not null check (frequency between 0 and 5),
	monetary_value int not null check (monetary_value between 0 and 5)
)
```

### 1.4.3. Напишите SQL запрос для заполнения витрины

Наконец, реализуйте расчет витрины на языке SQL и заполните таблицу, созданную в предыдущем пункте.

Для решения предоставьте код запроса.

```SQL
insert into analysis.dm_rfm_segments (user_id, recency, frequency, monetary_value)
    (
    select user_id, 
	       ntile(5) over (order by last_order_dt) as recency,
	       ntile(5) over (order by order_count) as frequency,
	       ntile(5) over (order by order_sum) as monetary_value
	from (
		select user_id, 
			   max(order_ts) as last_order_dt,
			   count(distinct order_id) as order_count,
			   sum(payment) as order_sum
		from analysis.orders_v o inner join analysis.orderstatuses_v os on o.status = os.id
		where os."key" = 'Closed'
	group by user_id) t1 
)

--or
insert into analysis.dm_rfm_segments (user_id, recency, frequency, monetary_value) (
	select user_id, recency, frequency, monetary_value from analysis.dm_rfm_segments_v
)
```



