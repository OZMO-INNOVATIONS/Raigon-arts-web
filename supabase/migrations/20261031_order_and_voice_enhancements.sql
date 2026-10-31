-- ============================================================================
-- RAIGON ART: Complete Order Management & Reminders Voice Migration
-- Safe, non-destructive migration ensuring all new columns exist
-- ============================================================================

-- 1. Reminders Table: Add Voice URL and Duration
ALTER TABLE IF EXISTS public.reminders 
    ADD COLUMN IF NOT EXISTS voice_url TEXT DEFAULT '',
    ADD COLUMN IF NOT EXISTS voice_duration_seconds INTEGER DEFAULT 0;

-- 2. Customers / Orders Table: Add Expected Delivery Date & Status History
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'customers'
    ) THEN
        ALTER TABLE public.customers 
            ADD COLUMN IF NOT EXISTS expected_delivery TIMESTAMP WITH TIME ZONE,
            ADD COLUMN IF NOT EXISTS status_history JSONB DEFAULT '[]'::jsonb,
            ADD COLUMN IF NOT EXISTS frames JSONB DEFAULT '[]'::jsonb,
            ADD COLUMN IF NOT EXISTS photo_urls TEXT[] DEFAULT ARRAY[]::TEXT[],
            ADD COLUMN IF NOT EXISTS photo_names TEXT[] DEFAULT ARRAY[]::TEXT[];
    END IF;
END $$;

-- 3. Create helpful index for expected delivery date queries
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'customers'
    ) THEN
        CREATE INDEX IF NOT EXISTS idx_customers_expected_delivery 
            ON public.customers (expected_delivery);
        CREATE INDEX IF NOT EXISTS idx_customers_status 
            ON public.customers (status);
    END IF;
END $$;

