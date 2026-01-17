-- ============================================================
-- Migration: 006_add_projects_module.sql
-- Version: 7
-- Description: Agrega módulo completo de proyectos (tablas y permisos)
-- Date: 2026-01-17
-- Author: Gestionarte Team
-- ============================================================
-- NOTA: Este módulo permite gestionar proyectos institucionales
-- con hitos, participantes, actas y documentos.
-- ============================================================

-- ============================================================
-- 1. TABLA PRINCIPAL: projects
-- ============================================================
CREATE TABLE IF NOT EXISTS public.projects (
    project_id uuid NOT NULL DEFAULT gen_random_uuid(),
    project_name character varying(200) NOT NULL,
    project_description text,
    project_purpose text NOT NULL,
    project_objective text NOT NULL,
    objective_target_value numeric,
    objective_current_value numeric,
    objective_unit character varying(50),
    leader_email character varying NOT NULL,
    leader_name character varying NOT NULL,
    start_date date NOT NULL,
    expected_end_date date NOT NULL,
    actual_end_date date,
    project_status character varying NOT NULL DEFAULT 'Activo'::character varying
        CHECK (project_status::text = ANY (ARRAY['Activo'::character varying, 'En Pausa'::character varying, 'Completado'::character varying, 'Cancelado'::character varying]::text[])),
    status_change_reason text,
    created_by uuid NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT projects_pkey PRIMARY KEY (project_id),
    CONSTRAINT projects_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id)
);

-- Índices para projects
CREATE INDEX IF NOT EXISTS idx_projects_leader_email ON public.projects(leader_email);
CREATE INDEX IF NOT EXISTS idx_projects_status ON public.projects(project_status);
CREATE INDEX IF NOT EXISTS idx_projects_created_by ON public.projects(created_by);

-- Comentarios
COMMENT ON TABLE public.projects IS 'Proyectos del módulo de gestión de proyectos';
COMMENT ON COLUMN public.projects.objective_target_value IS 'Valor meta del objetivo (solo si es cuantificable)';
COMMENT ON COLUMN public.projects.objective_current_value IS 'Valor actual del objetivo (solo si es cuantificable)';
COMMENT ON COLUMN public.projects.objective_unit IS 'Unidad de medida del objetivo (ej: %, unidades, etc.)';

-- ============================================================
-- 2. TABLA: project_participants
-- ============================================================
CREATE TABLE IF NOT EXISTS public.project_participants (
    participant_id uuid NOT NULL DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL,
    user_email character varying NOT NULL,
    worker_name character varying NOT NULL,
    participant_role character varying NOT NULL
        CHECK (participant_role::text = ANY (ARRAY['Colaborador'::character varying, 'Observador'::character varying]::text[])),
    added_by uuid NOT NULL,
    added_by_name character varying,
    added_at timestamp with time zone NOT NULL DEFAULT now(),
    participant_status character varying NOT NULL DEFAULT 'active'::character varying
        CHECK (participant_status::text = ANY (ARRAY['active'::character varying, 'removed'::character varying]::text[])),
    removed_at timestamp with time zone,
    removed_by uuid,
    removal_reason text,
    CONSTRAINT project_participants_pkey PRIMARY KEY (participant_id),
    CONSTRAINT project_participants_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(project_id) ON DELETE CASCADE,
    CONSTRAINT project_participants_added_by_fkey FOREIGN KEY (added_by) REFERENCES public.users(user_id),
    CONSTRAINT project_participants_removed_by_fkey FOREIGN KEY (removed_by) REFERENCES public.users(user_id)
);

-- Índices para project_participants
CREATE INDEX IF NOT EXISTS idx_project_participants_project ON public.project_participants(project_id);
CREATE INDEX IF NOT EXISTS idx_project_participants_email ON public.project_participants(user_email);
CREATE INDEX IF NOT EXISTS idx_project_participants_status ON public.project_participants(participant_status);

-- Comentarios
COMMENT ON TABLE public.project_participants IS 'Participantes de proyectos (colaboradores y observadores). El líder NO se registra aquí.';

-- ============================================================
-- 3. TABLA: project_milestones
-- ============================================================
CREATE TABLE IF NOT EXISTS public.project_milestones (
    milestone_id uuid NOT NULL DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL,
    milestone_name character varying(200) NOT NULL,
    milestone_description text,
    milestone_order integer NOT NULL DEFAULT 1,
    committed_date date NOT NULL,
    actual_date date,
    milestone_status character varying NOT NULL DEFAULT 'Pendiente'::character varying
        CHECK (milestone_status::text = ANY (ARRAY['Pendiente'::character varying, 'Cumplido'::character varying, 'Vencido'::character varying]::text[])),
    completion_notes text,
    created_by uuid NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT project_milestones_pkey PRIMARY KEY (milestone_id),
    CONSTRAINT project_milestones_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(project_id) ON DELETE CASCADE,
    CONSTRAINT project_milestones_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id)
);

-- Índices para project_milestones
CREATE INDEX IF NOT EXISTS idx_project_milestones_project ON public.project_milestones(project_id);
CREATE INDEX IF NOT EXISTS idx_project_milestones_status ON public.project_milestones(milestone_status);
CREATE INDEX IF NOT EXISTS idx_project_milestones_committed_date ON public.project_milestones(committed_date);

-- Comentarios
COMMENT ON TABLE public.project_milestones IS 'Hitos de los proyectos con fechas comprometidas y reales';

-- ============================================================
-- 4. TABLA: project_minutes (Actas de reuniones)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.project_minutes (
    minute_id uuid NOT NULL DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL,
    meeting_date date NOT NULL,
    meeting_time time without time zone,
    attendees jsonb NOT NULL DEFAULT '[]'::jsonb,
    topics_discussed text NOT NULL,
    decisions text,
    commitments text,
    additional_notes text,
    recorded_by uuid NOT NULL,
    recorded_by_name character varying NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT project_minutes_pkey PRIMARY KEY (minute_id),
    CONSTRAINT project_minutes_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(project_id) ON DELETE CASCADE,
    CONSTRAINT project_minutes_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES public.users(user_id)
);

-- Índices para project_minutes
CREATE INDEX IF NOT EXISTS idx_project_minutes_project ON public.project_minutes(project_id);
CREATE INDEX IF NOT EXISTS idx_project_minutes_date ON public.project_minutes(meeting_date);

-- Comentarios
COMMENT ON TABLE public.project_minutes IS 'Actas de reuniones de los proyectos';
COMMENT ON COLUMN public.project_minutes.attendees IS 'Array JSON de asistentes: [{email, name, role}]';

-- ============================================================
-- 5. TABLA: project_documents
-- ============================================================
CREATE TABLE IF NOT EXISTS public.project_documents (
    document_id uuid NOT NULL DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL,
    document_name character varying(255) NOT NULL,
    document_description text,
    storage_path character varying NOT NULL,
    file_size integer,
    mime_type character varying(100),
    uploaded_by uuid NOT NULL,
    uploaded_by_name character varying NOT NULL,
    uploaded_at timestamp with time zone NOT NULL DEFAULT now(),
    document_status character varying NOT NULL DEFAULT 'active'::character varying
        CHECK (document_status::text = ANY (ARRAY['active'::character varying, 'deleted'::character varying]::text[])),
    deleted_at timestamp with time zone,
    deleted_by uuid,
    CONSTRAINT project_documents_pkey PRIMARY KEY (document_id),
    CONSTRAINT project_documents_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(project_id) ON DELETE CASCADE,
    CONSTRAINT project_documents_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.users(user_id),
    CONSTRAINT project_documents_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id)
);

-- Índices para project_documents
CREATE INDEX IF NOT EXISTS idx_project_documents_project ON public.project_documents(project_id);
CREATE INDEX IF NOT EXISTS idx_project_documents_status ON public.project_documents(document_status);

-- Comentarios
COMMENT ON TABLE public.project_documents IS 'Documentos adjuntos a los proyectos';

-- ============================================================
-- 6. MODIFICAR TABLA tasks: Agregar project_id y actualizar CHECK
-- ============================================================

-- 6.1 Agregar columna project_id
ALTER TABLE public.tasks 
ADD COLUMN IF NOT EXISTS project_id uuid;

-- 6.2 Agregar FK a projects
ALTER TABLE public.tasks
DROP CONSTRAINT IF EXISTS tasks_project_id_fkey;

ALTER TABLE public.tasks
ADD CONSTRAINT tasks_project_id_fkey 
FOREIGN KEY (project_id) REFERENCES public.projects(project_id);

-- 6.3 Actualizar CHECK constraint de module_type para incluir 'projects'
-- Primero eliminar el constraint existente
ALTER TABLE public.tasks
DROP CONSTRAINT IF EXISTS tasks_module_type_check;

-- Luego crear el nuevo constraint con 'projects' incluido
ALTER TABLE public.tasks
ADD CONSTRAINT tasks_module_type_check 
CHECK (module_type::text = ANY (ARRAY[
    'procedures'::character varying, 
    'kpi_improvement'::character varying, 
    'general'::character varying, 
    'projects'::character varying,
    'other'::character varying
]::text[]));

-- Índice para project_id en tasks
CREATE INDEX IF NOT EXISTS idx_tasks_project_id ON public.tasks(project_id);

-- Comentario
COMMENT ON COLUMN public.tasks.project_id IS 'ID del proyecto asociado (si module_type = projects)';

-- ============================================================
-- 7. PERMISOS DEL MÓDULO DE PROYECTOS
-- ============================================================
INSERT INTO public.permissions (permission_name, permission_description, permission_status, module_id, page_url) 
VALUES
    ('Proyectos', 'Acceso al listado de proyectos donde el usuario participa y opciones de gestión del proyecto', 'active', 'general-tools', '/modules/general-tools/projects.html'),
    ('Dashboard proyectos', 'Acceso al dashboard ejecutivo de proyectos. Permite ver TODOS los proyectos en modo solo lectura.', 'active', 'general-tools', '/modules/general-tools/projects-dashboard.html')
ON CONFLICT (permission_name) DO NOTHING;

-- ============================================================
-- FIN DE MIGRACIÓN 006
-- ============================================================
