create function is_admin() returns boolean language sql stable security definer set search_path = public as
$$ select exists (select 1 from profiles where id = auth.uid() and role = 'admin') $$;
create function my_customer_ids() returns setof uuid language sql stable security definer set search_path = public as
$$ select id from customers where user_id = auth.uid() $$;

alter table profiles enable row level security;
alter table customers enable row level security;
alter table deliveries enable row level security;
alter table payments enable row level security;

create policy profiles_self on profiles for select using (id = auth.uid() or is_admin());
create policy cust_admin on customers for all using (is_admin()) with check (is_admin());
create policy cust_own on customers for select using (user_id = auth.uid());
create policy del_admin on deliveries for all using (is_admin()) with check (is_admin());
create policy del_own on deliveries for select using (customer_id in (select my_customer_ids()));
create policy pay_admin on payments for all using (is_admin()) with check (is_admin());
create policy pay_own_read on payments for select using (customer_id in (select my_customer_ids()));
create policy pay_own_insert on payments for insert
  with check (customer_id in (select my_customer_ids()) and status = 'pending');
