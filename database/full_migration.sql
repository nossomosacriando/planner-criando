-- ================================================
-- CRIANDO PLANNER - RESET & FULL MIGRATION SCRIPT
-- ================================================

-- 1. DROPPAR ESTRUTURAS ANTIGAS PARA RECRIAR LIMPO
DROP TABLE IF EXISTS public.activity_log CASCADE;
DROP TABLE IF EXISTS public.task_members CASCADE;
DROP TABLE IF EXISTS public.tasks CASCADE;
DROP TABLE IF EXISTS public.project_members CASCADE;
DROP TABLE IF EXISTS public.projects CASCADE;
DROP TABLE IF EXISTS public.members CASCADE;

-- Extension for UUID generation if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. RECRIAR TABELAS

-- MEMBERS
CREATE TABLE public.members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE SET NULL,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    name TEXT NOT NULL,
    role TEXT,
    role_level TEXT DEFAULT 'user', -- 'master', 'moderator', 'user'
    avatar TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- PROJECTS
CREATE TABLE public.projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    icon TEXT DEFAULT '📁',
    color TEXT DEFAULT '#3b82f6',
    owner_id UUID REFERENCES public.members(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- PROJECT MEMBERS (N:M relationship)
CREATE TABLE public.project_members (
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
    member_id UUID REFERENCES public.members(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member',
    PRIMARY KEY (project_id, member_id)
);

-- TASKS
CREATE TABLE public.tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'backlog',
    start_date DATE,
    end_date DATE,
    created_by UUID REFERENCES public.members(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES public.members(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- TASK MEMBERS (N:M relationship)
CREATE TABLE public.task_members (
    task_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE,
    member_id UUID REFERENCES public.members(id) ON DELETE CASCADE,
    PRIMARY KEY (task_id, member_id)
);

-- ACTIVITY LOG
CREATE TABLE public.activity_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE,
    member_id UUID REFERENCES public.members(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. TRIGGERS DE UPDATED_AT
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_members_updated_at BEFORE UPDATE ON public.members FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 4. RLS POLICIES (PERMISSÕES DE LEITURA E ESCRITA PARA PUBLIC / ANON / AUTHENTICATED)
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read on projects" ON public.projects FOR SELECT USING (true);
CREATE POLICY "Allow public insert on projects" ON public.projects FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update on projects" ON public.projects FOR UPDATE USING (true);
CREATE POLICY "Allow public delete on projects" ON public.projects FOR DELETE USING (true);

CREATE POLICY "Allow public read on project_members" ON public.project_members FOR SELECT USING (true);
CREATE POLICY "Allow public insert on project_members" ON public.project_members FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update on project_members" ON public.project_members FOR UPDATE USING (true);
CREATE POLICY "Allow public delete on project_members" ON public.project_members FOR DELETE USING (true);

CREATE POLICY "Allow public read on members" ON public.members FOR SELECT USING (true);
CREATE POLICY "Allow public insert on members" ON public.members FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update on members" ON public.members FOR UPDATE USING (true);
CREATE POLICY "Allow public delete on members" ON public.members FOR DELETE USING (true);

CREATE POLICY "Allow public read on tasks" ON public.tasks FOR SELECT USING (true);
CREATE POLICY "Allow public insert on tasks" ON public.tasks FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update on tasks" ON public.tasks FOR UPDATE USING (true);
CREATE POLICY "Allow public delete on tasks" ON public.tasks FOR DELETE USING (true);

CREATE POLICY "Allow public read on task_members" ON public.task_members FOR SELECT USING (true);
CREATE POLICY "Allow public insert on task_members" ON public.task_members FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public delete on task_members" ON public.task_members FOR DELETE USING (true);

-- 5. HABILITAR SUPABASE REALTIME
DROP PUBLICATION IF EXISTS supabase_realtime;
CREATE PUBLICATION supabase_realtime FOR TABLE public.projects, public.project_members, public.members, public.tasks, public.task_members, public.activity_log;

-- 6. DADOS INICIAIS (SEED V3 COM OWNERS E INTEGRANTES)

-- Membros
INSERT INTO public.members (id, username, password, name, role, role_level, avatar) VALUES
('a1111111-1111-1111-1111-111111111111', 'Carlos', 'S&nha@master', 'Carlos Santana', 'Responsável por O Leitor · apoio em O Lobby e Lime Verso', 'master', 'CS'),
('b2222222-2222-2222-2222-222222222222', 'Davi', 'S&nha@123', 'Davi Silveira', 'Responsável por Lime Verso · apoio em O Lobby', 'user', 'DS'),
('c3333333-3333-3333-3333-333333333333', 'Will', 'S&nha@123', 'Willian Oliveira', 'Responsável por Harvast Words · apoio em O Lobby', 'moderator', 'WO');

-- Projetos (Willian = Owner de Harvast Words | Carlos = Owner dos demais)
INSERT INTO public.projects (id, name, icon, color, owner_id) VALUES
('11111111-1111-1111-1111-111111111111', 'Harvast Words', '🎮', '#2563eb', 'c3333333-3333-3333-3333-333333333333'),
('22222222-2222-2222-2222-222222222222', 'O Leitor', '📖', '#ec4899', 'a1111111-1111-1111-1111-111111111111'),
('33333333-3333-3333-3333-333333333333', 'O Lobby', '👤', '#10b981', 'a1111111-1111-1111-1111-111111111111'),
('44444444-4444-4444-4444-444444444444', 'Lime Verso', '🌿', '#8b5cf6', 'a1111111-1111-1111-1111-111111111111');

-- Associação de Membros aos Projetos
INSERT INTO public.project_members (project_id, member_id, role) VALUES
('11111111-1111-1111-1111-111111111111', 'c3333333-3333-3333-3333-333333333333', 'owner'),
('11111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', 'member'),
('22222222-2222-2222-2222-222222222222', 'a1111111-1111-1111-1111-111111111111', 'owner'),
('33333333-3333-3333-3333-333333333333', 'a1111111-1111-1111-1111-111111111111', 'owner'),
('33333333-3333-3333-3333-333333333333', 'b2222222-2222-2222-2222-222222222222', 'member'),
('33333333-3333-3333-3333-333333333333', 'c3333333-3333-3333-3333-333333333333', 'member'),
('44444444-4444-4444-4444-444444444444', 'a1111111-1111-1111-1111-111111111111', 'owner'),
('44444444-4444-4444-4444-444444444444', 'b2222222-2222-2222-2222-222222222222', 'member');

-- Tarefas Iniciais do v3
INSERT INTO public.tasks (id, project_id, title, description, status, start_date, end_date, created_by) VALUES
('a1111111-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Conectando o jogo online', 'Implementar e estruturar a conexão online do jogo.', 'andamento', '2026-05-24', '2026-07-06', 'c3333333-3333-3333-3333-333333333333'),
('a1111111-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'Globalização', 'Trabalhar a globalização e expansão do projeto.', 'pausado', '2026-05-18', '2026-06-01', 'a1111111-1111-1111-1111-111111111111'),
('a1111111-0000-0000-0000-000000000003', '22222222-2222-2222-2222-222222222222', 'Correção de bugs', 'Corrigir bugs identificados durante os testes.', 'testes', '2026-06-26', '2026-07-02', 'a1111111-1111-1111-1111-111111111111'),
('a1111111-0000-0000-0000-000000000004', '33333333-3333-3333-3333-333333333333', 'Refinamento', 'Refinamento geral da aplicação e experiência do usuário.', 'andamento', '2026-05-20', '2026-06-10', 'a1111111-1111-1111-1111-111111111111'),
('a1111111-0000-0000-0000-000000000005', '44444444-4444-4444-4444-444444444444', 'Desenvolvimento', 'Desenvolvimento das funcionalidades principais do projeto.', 'andamento', '2026-05-25', '2026-06-15', 'b2222222-2222-2222-2222-222222222222');

-- Associação de Membros às Tarefas
INSERT INTO public.task_members (task_id, member_id) VALUES
('a1111111-0000-0000-0000-000000000001', 'c3333333-3333-3333-3333-333333333333'),
('a1111111-0000-0000-0000-000000000002', 'a1111111-1111-1111-1111-111111111111'),
('a1111111-0000-0000-0000-000000000003', 'a1111111-1111-1111-1111-111111111111'),
('a1111111-0000-0000-0000-000000000004', 'a1111111-1111-1111-1111-111111111111'),
('a1111111-0000-0000-0000-000000000004', 'b2222222-2222-2222-2222-222222222222'),
('a1111111-0000-0000-0000-000000000004', 'c3333333-3333-3333-3333-333333333333'),
('a1111111-0000-0000-0000-000000000005', 'a1111111-1111-1111-1111-111111111111'),
('a1111111-0000-0000-0000-000000000005', 'b2222222-2222-2222-2222-222222222222');
