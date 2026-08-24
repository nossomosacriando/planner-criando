// ================================================
// CRIANDO PLANNER - DATA SERVICES & SUPABASE CLIENT
// ================================================

/**
 * Configuração e inicialização do cliente Supabase.
 * As variáveis SUPABASE_URL e SUPABASE_ANON_KEY devem ser configuradas.
 */
const SUPABASE_URL = window.ENV?.SUPABASE_URL || "YOUR_SUPABASE_URL";
const SUPABASE_ANON_KEY = window.ENV?.SUPABASE_ANON_KEY || "YOUR_SUPABASE_ANON_KEY";

// Instância singleton do cliente Supabase (usando a lib global window.supabase)
let supabaseClient = null;

export function getSupabase() {
  if (!supabaseClient && window.supabase) {
    supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  }
  return supabaseClient;
}

// ------------------------------------------------
// 1. AUTH SERVICE
// ------------------------------------------------
export const AuthService = {
  async getCurrentUser() {
    const supabase = getSupabase();
    if (!supabase) return null;
    const { data: { user } } = await supabase.auth.getUser();
    return user;
  },

  async getCurrentMember() {
    const user = await this.getCurrentUser();
    if (!user) return null;
    const supabase = getSupabase();
    const { data, error } = await supabase
      .from('members')
      .select('*')
      .eq('auth_user_id', user.id)
      .single();
    if (error) console.error("Erro ao buscar perfil do membro:", error);
    return data;
  },

  async signInWithEmail(email, password) {
    const supabase = getSupabase();
    if (!supabase) return { error: "Supabase client not initialized" };
    return await supabase.auth.signInWithPassword({ email, password });
  },

  async signOut() {
    const supabase = getSupabase();
    if (!supabase) return;
    return await supabase.auth.signOut();
  }
};

// ------------------------------------------------
// 2. PROJECTS SERVICE
// ------------------------------------------------
export const ProjectsService = {
  async fetchProjects() {
    const supabase = getSupabase();
    if (!supabase) return [];
    const { data, error } = await supabase.from('projects').select('*').order('name');
    if (error) {
      console.error("Erro ao buscar projetos:", error);
      return [];
    }
    return data;
  },

  async createProject(project) {
    const supabase = getSupabase();
    if (!supabase) return null;
    const { data, error } = await supabase.from('projects').insert([project]).select().single();
    if (error) throw error;
    return data;
  }
};

// ------------------------------------------------
// 3. MEMBERS SERVICE
// ------------------------------------------------
export const MembersService = {
  async fetchMembers() {
    const supabase = getSupabase();
    if (!supabase) return [];
    const { data, error } = await supabase.from('members').select('*').order('name');
    if (error) {
      console.error("Erro ao buscar membros:", error);
      return [];
    }
    return data;
  },

  async saveMember(member) {
    const supabase = getSupabase();
    if (!supabase) return null;
    if (member.id) {
      const { data, error } = await supabase
        .from('members')
        .update({ name: member.name, role: member.role })
        .eq('id', member.id)
        .select()
        .single();
      if (error) throw error;
      return data;
    } else {
      const { data, error } = await supabase
        .from('members')
        .insert([{ name: member.name, role: member.role }])
        .select()
        .single();
      if (error) throw error;
      return data;
    }
  },

  async deleteMember(id) {
    const supabase = getSupabase();
    if (!supabase) return;
    const { error } = await supabase.from('members').delete().eq('id', id);
    if (error) throw error;
  }
};

// ------------------------------------------------
// 4. TASKS SERVICE
// ------------------------------------------------
export const TasksService = {
  async fetchTasks() {
    const supabase = getSupabase();
    if (!supabase) return [];
    
    // Busca tarefas com os relacionamentos de task_members
    const { data, error } = await supabase
      .from('tasks')
      .select(`
        *,
        task_members ( member_id )
      `)
      .order('created_at', { ascending: false });

    if (error) {
      console.error("Erro ao buscar tarefas:", error);
      return [];
    }

    // Formata o array para manter compatibilidade com a UI (members = array de IDs)
    return data.map(t => ({
      ...t,
      project: t.project_id,
      members: t.task_members ? t.task_members.map(tm => tm.member_id) : []
    }));
  },

  async saveTask(taskData, currentMemberId) {
    const supabase = getSupabase();
    if (!supabase) return null;

    const payload = {
      project_id: taskData.project,
      title: taskData.title,
      description: taskData.description,
      status: taskData.status || 'backlog',
      start_date: taskData.start_date || null,
      end_date: taskData.end_date || null,
      updated_by: currentMemberId
    };

    let taskId = taskData.id;

    if (taskId) {
      // Concorrência Otimista: Verifica se a tarefa foi alterada por outro usuário
      const { data: existing } = await supabase.from('tasks').select('updated_at').eq('id', taskId).single();
      if (existing && taskData.updated_at && new Date(existing.updated_at) > new Date(taskData.updated_at)) {
        const proceed = confirm("Esta tarefa foi alterada por outro usuário enquanto você editava. Deseja sobrescrever as alterações?");
        if (!proceed) return null;
      }

      const { data, error } = await supabase
        .from('tasks')
        .update(payload)
        .eq('id', taskId)
        .select()
        .single();

      if (error) throw error;

      // Atualiza associações de membros
      await supabase.from('task_members').delete().eq('task_id', taskId);
      if (taskData.members && taskData.members.length > 0) {
        const memberRows = taskData.members.map(mId => ({ task_id: taskId, member_id: mId }));
        await supabase.from('task_members').insert(memberRows);
      }

      return data;
    } else {
      payload.created_by = currentMemberId;
      const { data, error } = await supabase.from('tasks').insert([payload]).select().single();
      if (error) throw error;

      if (taskData.members && taskData.members.length > 0) {
        const memberRows = taskData.members.map(mId => ({ task_id: data.id, member_id: mId }));
        await supabase.from('task_members').insert(memberRows);
      }

      return data;
    }
  },

  async updateTaskStatus(taskId, newStatus, currentMemberId) {
    const supabase = getSupabase();
    if (!supabase) return;
    const { error } = await supabase
      .from('tasks')
      .update({ status: newStatus, updated_by: currentMemberId })
      .eq('id', taskId);

    if (error) throw error;
  },

  async deleteTask(taskId) {
    const supabase = getSupabase();
    if (!supabase) return;
    const { error } = await supabase.from('tasks').delete().eq('id', taskId);
    if (error) throw error;
  }
};

// ------------------------------------------------
// 5. REALTIME SERVICE
// ------------------------------------------------
export const RealtimeService = {
  subscribeToChanges(onDataChange) {
    const supabase = getSupabase();
    if (!supabase) return null;

    const channel = supabase
      .channel('schema-db-changes')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public' },
        (payload) => {
          console.log('Realtime DB Event received:', payload);
          if (typeof onDataChange === 'function') {
            onDataChange(payload);
          }
        }
      )
      .subscribe();

    return channel;
  }
};
