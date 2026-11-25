insert into customers (name, phone, address, default_qty_litre, rate_per_litre, milk_type) values
('Ramesh Patil','9876543210','Shivaji Nagar',1,60,'cow'),('Sunita Jadhav','9822012345','Kothrud',2,60,'cow'),
('Anil Kulkarni','9890011223','Aundh',1.5,70,'buffalo'),('Meena Deshmukh','9923456789','Baner',1,60,'cow'),
('Prakash More','9765432109','Wakad',2,70,'buffalo'),('Kavita Shinde','9850123456','Pashan',1,60,'cow'),
('Sanjay Pawar','9811122233','Hadapsar',3,60,'cow'),('Rekha Gaikwad','9922334455','Karve Nagar',1,70,'buffalo'),
('Vijay Bhosale','9890098765','Viman Nagar',2,60,'cow'),('Asha Kale','9764455667','Katraj',1,60,'cow');
-- Make yourself admin after creating your user in Supabase Auth:
-- insert into profiles(id, role, name) values ('<AUTH_USER_UUID>', 'admin', 'Owner')
--   on conflict (id) do update set role = 'admin';
