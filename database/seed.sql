-- ================================================
-- CRIANDO PLANNER - SEED INITIAL DATA
-- ================================================

-- Insert default projects
INSERT INTO public.projects (id, name, icon, color) VALUES
('11111111-1111-1111-1111-111111111111', 'Lançamento App Criando', '🚀', '#2563eb'),
('22222222-2222-2222-2222-222222222222', 'Marketing & Redes', '📢', '#ec4899'),
('33333333-3333-3333-3333-333333333333', 'Infraestrutura Cloud', '☁️', '#10b981')
ON CONFLICT (id) DO NOTHING;

-- Insert default members
INSERT INTO public.members (id, name, role, avatar) VALUES
('a1111111-1111-1111-1111-111111111111', 'Carlos Santana', 'Tech Lead', 'CS'),
('b2222222-2222-2222-2222-222222222222', 'Davi Silveira', 'Fullstack Developer', 'DS'),
('c3333333-3333-3333-3333-333333333333', 'Willian Gonçalves', 'Product Owner', 'WG')
ON CONFLICT (id) DO NOTHING;

-- Insert initial tasks
INSERT INTO public.tasks (id, project_id, title, description, status, start_date, end_date, created_by) VALUES
('a1111111-2222-3333-4444-555555555555', '11111111-1111-1111-1111-111111111111', 'Arquitetura Backend Supabase', 'Estruturação do banco PostgreSQL, tabelas, RLS e subscriptions Realtime.', 'in_progress', CURRENT_DATE, CURRENT_DATE + INTERVAL '7 days', 'a1111111-1111-1111-1111-111111111111'),
('a2222222-2222-3333-4444-555555555555', '11111111-1111-1111-1111-111111111111', 'Integração Supabase Auth', 'Substituir perfil mock visual por autenticação via Supabase Auth e sessão do usuário.', 'backlog', CURRENT_DATE + INTERVAL '2 days', CURRENT_DATE + INTERVAL '10 days', 'b2222222-2222-2222-2222-222222222222')
ON CONFLICT (id) DO NOTHING;

-- Assign members to tasks
INSERT INTO public.task_members (task_id, member_id) VALUES
('a1111111-2222-3333-4444-555555555555', 'a1111111-1111-1111-1111-111111111111'),
('a1111111-2222-3333-4444-555555555555', 'b2222222-2222-2222-2222-222222222222'),
('a2222222-2222-3333-4444-555555555555', 'c3333333-3333-3333-3333-333333333333')
ON CONFLICT DO NOTHING;

