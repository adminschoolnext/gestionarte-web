-- ============================================================
-- Migration: 005_add_survey_question_logic.sql
-- Version: 6
-- Description: Agrega sistema de lógica condicional (skip logic) para encuestas
-- Date: 2025-12-19
-- Author: GestionArte Team
-- ============================================================

CREATE TABLE IF NOT EXISTS public.survey_question_logic (
    logic_id uuid NOT NULL DEFAULT gen_random_uuid(),
    question_id uuid NOT NULL,
    condition_type character varying(50) NOT NULL 
        CHECK (condition_type::text = ANY (ARRAY['equals'::character varying, 'not_equals'::character varying, 'contains'::character varying, 'greater_than'::character varying, 'less_than'::character varying]::text[])),
    condition_value text NOT NULL,
    target_section_id uuid NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    created_by uuid NOT NULL,
    CONSTRAINT survey_question_logic_pkey PRIMARY KEY (logic_id),
    CONSTRAINT survey_question_logic_question_fkey FOREIGN KEY (question_id) REFERENCES public.survey_questions(question_id) ON DELETE CASCADE,
    CONSTRAINT survey_question_logic_target_section_fkey FOREIGN KEY (target_section_id) REFERENCES public.survey_sections(section_id) ON DELETE CASCADE,
    CONSTRAINT survey_question_logic_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id),
    CONSTRAINT survey_question_logic_unique_active UNIQUE (question_id, is_active)
);

-- Comentarios
COMMENT ON TABLE public.survey_question_logic IS 
'Lógica condicional para encuestas (skip logic). Permite saltar a secciones específicas según respuesta. Agregada en migración 003.';
COMMENT ON COLUMN public.survey_question_logic.question_id IS 
'ID de la pregunta que tiene la regla condicional';
COMMENT ON COLUMN public.survey_question_logic.condition_type IS 
'Tipo de condición: equals, not_equals, contains, greater_than, less_than';
COMMENT ON COLUMN public.survey_question_logic.condition_value IS 
'Valor que debe cumplir la respuesta para activar el salto';
COMMENT ON COLUMN public.survey_question_logic.target_section_id IS 
'ID de la sección a la que se saltará si se cumple la condición';

-- Índices
CREATE INDEX IF NOT EXISTS idx_survey_question_logic_question 
    ON public.survey_question_logic(question_id) 
    WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_survey_question_logic_target_section 
    ON public.survey_question_logic(target_section_id);
