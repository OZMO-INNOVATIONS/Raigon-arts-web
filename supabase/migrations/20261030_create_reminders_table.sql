-- RAIGON ART: Reminders Table Migration
-- Run this in Supabase SQL Editor if creating or updating the schema

CREATE TABLE IF NOT EXISTS public.reminders (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    customer_name TEXT NOT NULL,
    customer_id TEXT,
    order_id TEXT,
    description TEXT,
    reminder_date TIMESTAMP WITH TIME ZONE NOT NULL,
    reminder_time TEXT DEFAULT '10:00 AM',
    assigned_staff TEXT DEFAULT 'Admin',
    priority TEXT DEFAULT 'Medium',
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP WITH TIME ZONE,
    completed_by TEXT,
    created_by TEXT DEFAULT 'Admin',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    phone TEXT,
    region TEXT
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_reminders_date ON public.reminders (reminder_date);
CREATE INDEX IF NOT EXISTS idx_reminders_status ON public.reminders (is_completed);
CREATE INDEX IF NOT EXISTS idx_reminders_customer ON public.reminders (customer_id);

-- Enable RLS and set public policies for authenticated workshop staff
ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'reminders' AND policyname = 'Allow authenticated users full access'
    ) THEN
        CREATE POLICY "Allow authenticated users full access"
        ON public.reminders FOR ALL TO authenticated USING (true) WITH CHECK (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'reminders' AND policyname = 'Allow anon full access'
    ) THEN
        CREATE POLICY "Allow anon full access"
        ON public.reminders FOR ALL TO anon USING (true) WITH CHECK (true);
    END IF;
END $$;
