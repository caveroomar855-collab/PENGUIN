-- Migration: Make `codigo` optional / remove `color` (and optionally drop `codigo`)
--
-- WARNING: Review and run on a test database first. If you want to completely remove
-- the columns from production, run the "Drop columns" section after verifying no
-- application or SQL depends on them.
--
-- This file provides two approaches:
-- 1) SAFE: drop the unique constraint on `codigo` and make it nullable; drop `color` column.
-- 2) DESTROY: drop both `codigo` and `color` columns (DESRUCTIVE -- irreversible without backup).

BEGIN;

-- ---------------------------------------------------------
-- SAFE: remove unique constraint and make `codigo` nullable
-- ---------------------------------------------------------
-- Drop unique constraint on codigo if it exists
ALTER TABLE IF EXISTS public.articulos
  DROP CONSTRAINT IF EXISTS articulos_codigo_key;

-- Make codigo nullable (if previously NOT NULL)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='articulos' AND column_name='codigo'
  ) THEN
    EXECUTE 'ALTER TABLE public.articulos ALTER COLUMN codigo DROP NOT NULL';
  END IF;
END$$;

-- Drop color column if you no longer want it (safe if app no longer uses it)
ALTER TABLE IF EXISTS public.articulos
  DROP COLUMN IF EXISTS color;

-- Optionally remove the unique index on codigo (if any other name remains)
-- Drop index by name if it exists
DROP INDEX IF EXISTS public.articulos_codigo_key;

-- Notes:
-- - After this block, `codigo` will be nullable and no longer unique. The frontend
--   already stopped sending `codigo`, so this makes inserts safe.
-- - `color` column is removed entirely. If you prefer to keep it but nullable, remove
--   the DROP COLUMN line above and instead run:
--     ALTER TABLE public.articulos ALTER COLUMN color DROP NOT NULL;

-- ---------------------------------------------------------
-- OPTIONAL DESTRUCTIVE: DROP BOTH COLUMNS (UNCOMMENT TO RUN)
-- ---------------------------------------------------------
-- If you are sure you want to remove the columns entirely (destructive),
-- uncomment and run the following block. Make a DB backup first.
--
-- ALTER TABLE IF EXISTS public.articulos
--   DROP COLUMN IF EXISTS codigo;
--
-- ALTER TABLE IF EXISTS public.articulos
--   DROP COLUMN IF EXISTS color;
--
-- Also consider removing or updating any SQL functions, views or triggers that
-- reference `codigo` or `color` (search for occurrences in your DB scripts):
--   - backend/database/SUPABASE_SETUP.sql
--   - any reporting functions/views
--
-- Example: update a reporting SQL that used articulos.codigo to use articulos.nombre instead.
-- Ensure you update any application code or SQL that assumed `codigo` existed.

COMMIT;

-- End of migration
