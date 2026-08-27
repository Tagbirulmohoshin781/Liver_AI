-- =============================================================================
-- Supabase Row-Level Security (RLS) & Zero-Trust Schema Migration
-- Project: LiverAI Precision Diagnostics & Analytics
-- =============================================================================

-- 1. Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT auth.uid(),
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    role TEXT DEFAULT 'Patient',
    age INT,
    gender TEXT,
    blood_group TEXT,
    medical_notes TEXT,
    has_hepatitis_history BOOLEAN DEFAULT FALSE,
    has_fatty_liver_history BOOLEAN DEFAULT FALSE,
    alcohol_consumption BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);


-- 2. Chat Sessions Table
CREATE TABLE IF NOT EXISTS public.chat_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    session_title TEXT DEFAULT 'Liver Health Consultation',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own chat sessions"
    ON public.chat_sessions FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- 3. Chat Messages Table
CREATE TABLE IF NOT EXISTS public.chat_messages (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    session_id TEXT DEFAULT 'default',
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own chat messages"
    ON public.chat_messages FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- 4. Clinical Records Table (LPD 10-Biomarker Risk Evaluation)
CREATE TABLE IF NOT EXISTS public.clinical_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    age INT NOT NULL,
    gender TEXT NOT NULL,
    total_bilirubin NUMERIC(4,2) NOT NULL,
    direct_bilirubin NUMERIC(4,2) NOT NULL,
    alkaline_phosphotase NUMERIC(6,2) NOT NULL,
    sgpt NUMERIC(6,2) NOT NULL,
    sgot NUMERIC(6,2) NOT NULL,
    total_proteins NUMERIC(4,2) NOT NULL,
    albumin NUMERIC(4,2) NOT NULL,
    ag_ratio NUMERIC(4,2) NOT NULL,
    risk_probability NUMERIC(5,4) NOT NULL,
    risk_label TEXT NOT NULL,
    risk_level TEXT NOT NULL,
    contributing_factors JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.clinical_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own clinical records"
    ON public.clinical_records FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- 5. Uploads & Biopsy Analysis Table
CREATE TABLE IF NOT EXISTS public.uploads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    upload_token TEXT UNIQUE NOT NULL,
    original_filename TEXT NOT NULL,
    mime_type TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    biopsy_predictions JSONB DEFAULT '{}'::jsonb,
    is_image BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.uploads ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own uploads"
    ON public.uploads FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
