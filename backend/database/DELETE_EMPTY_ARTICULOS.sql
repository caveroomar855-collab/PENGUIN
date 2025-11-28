-- Delete articulos with non-positive quantity after sales
-- Run this in Supabase if you want to clean up any items that reached 0 quantity.

BEGIN;

-- Delete from articulos where cantidad <= 0
DELETE FROM public.articulos
WHERE cantidad <= 0;

COMMIT;
