-- ================================================
-- CRIANDO PLANNER - ROW LEVEL SECURITY (RLS) POLICIES
-- ================================================

-- Enable Row Level Security (RLS) on all tables
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------
-- 1. PROJECTS POLICIES
-- ------------------------------------------------
-- Authenticated users can view projects
CREATE POLICY "Allow authenticated read on projects"
ON public.projects FOR SELECT
TO authenticated
USING (true);

-- Authenticated users can insert/update projects
CREATE POLICY "Allow authenticated insert on projects"
ON public.projects FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Allow authenticated update on projects"
ON public.projects FOR UPDATE
TO authenticated
USING (true);

-- ------------------------------------------------
-- 2. MEMBERS POLICIES
-- ------------------------------------------------
-- Authenticated users can view members
CREATE POLICY "Allow authenticated read on members"
ON public.members FOR SELECT
TO authenticated
USING (true);

-- Authenticated users can manage member records
CREATE POLICY "Allow authenticated insert on members"
ON public.members FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Allow authenticated update on members"
ON public.members FOR UPDATE
TO authenticated
USING (true);

-- ------------------------------------------------
-- 3. TASKS POLICIES
-- ------------------------------------------------
-- Authenticated users can view tasks
CREATE POLICY "Allow authenticated read on tasks"
ON public.tasks FOR SELECT
TO authenticated
USING (true);

-- Authenticated users can create tasks
CREATE POLICY "Allow authenticated insert on tasks"
ON public.tasks FOR INSERT
TO authenticated
WITH CHECK (true);

-- Authenticated users can update tasks
CREATE POLICY "Allow authenticated update on tasks"
ON public.tasks FOR UPDATE
TO authenticated
USING (true);

-- Authenticated users can delete tasks
CREATE POLICY "Allow authenticated delete on tasks"
ON public.tasks FOR DELETE
TO authenticated
USING (true);

-- ------------------------------------------------
-- 4. TASK_MEMBERS POLICIES
-- ------------------------------------------------
CREATE POLICY "Allow authenticated read on task_members"
ON public.task_members FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow authenticated insert on task_members"
ON public.task_members FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Allow authenticated delete on task_members"
ON public.task_members FOR DELETE
TO authenticated
USING (true);

-- ------------------------------------------------
-- 5. ACTIVITY_LOG POLICIES
-- ------------------------------------------------
CREATE POLICY "Allow authenticated read on activity_log"
ON public.activity_log FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow authenticated insert on activity_log"
ON public.activity_log FOR INSERT
TO authenticated
WITH CHECK (true);
