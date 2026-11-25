create extension if not exists pgcrypto;
create table profiles(id uuid primary key references auth.users on delete cascade,
  role text not null default 'customer' check (role in ('admin','customer')), name text, phone text);
create table customers(id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users, name text not null,
  phone text unique not null check (phone ~ '^[0-9]{10}$'), address text,
  default_qty_litre numeric(5,2) not null default 1, rate_per_litre numeric(7,2) not null default 60,
  milk_type text default 'cow', is_active boolean not null default true, created_at timestamptz default now());
create table deliveries(id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references customers on delete restrict, date date not null,
  qty_litre numeric(5,2) not null, status text not null default 'delivered' check (status in ('delivered','skipped')),
  delivered_at timestamptz default now(), whatsapp_status text default 'pending', unique (customer_id, date));
create table payments(id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references customers on delete restrict, amount numeric(9,2) not null check (amount > 0),
  mode text not null check (mode in ('upi','cash','bank')), reference_no text, paid_on date not null default current_date,
  status text not null default 'pending' check (status in ('pending','confirmed','rejected')), confirmed_by uuid references auth.users);
create index on deliveries (customer_id, date);
create index on deliveries (date);
create index on payments (customer_id, paid_on);

create view monthly_bills with (security_invoker = true) as
with m as (select customer_id, date_trunc('month', date)::date as month, count(*) as days, sum(qty_litre) as litres
           from deliveries where status = 'delivered' group by 1, 2),
p as (select customer_id, date_trunc('month', paid_on)::date as month, sum(amount) as paid
      from payments where status = 'confirmed' group by 1, 2)
select m.customer_id, m.month, m.days, m.litres as total_litres, m.litres * c.rate_per_litre as total_amount,
  coalesce(p.paid, 0) as paid_amount, m.litres * c.rate_per_litre - coalesce(p.paid, 0) as balance
from m join customers c on c.id = m.customer_id
left join p on p.customer_id = m.customer_id and p.month = m.month;

-- Link a phone-OTP login to the matching customer record
create function handle_new_user() returns trigger language plpgsql security definer set search_path = public as $$
begin
  update customers set user_id = new.id where phone = right(coalesce(new.phone, ''), 10) and user_id is null;
  insert into profiles(id, role, phone) values (new.id, 'customer', new.phone) on conflict do nothing;
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function handle_new_user();
