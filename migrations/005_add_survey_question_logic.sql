-- ============================================================
-- CREAR TABLA: survey_question_logic
-- ============================================================

CREATE TABLE IF NOT EXISTS public.survey_question_logic (
  logic_id uuid NOT NULL DEFAULT gen_random_uuid(),
  question_id uuid NOT NULL,
  condition_type character varying(50) NOT NULL,
  condition_value text NOT NULL,
  target_section_id uuid NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  created_by uuid NOT NULL,
  
  CONSTRAINT survey_question_logic_pkey PRIMARY KEY (logic_id),
  CONSTRAINT survey_question_logic_unique_active UNIQUE (question_id, is_active),
  CONSTRAINT survey_question_logic_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES public.users (user_id),
  CONSTRAINT survey_question_logic_question_fkey 
    FOREIGN KEY (question_id) REFERENCES public.survey_questions (question_id) 
    ON DELETE CASCADE,
  CONSTRAINT survey_question_logic_target_section_fkey 
    FOREIGN KEY (target_section_id) REFERENCES public.survey_sections (section_id) 
    ON DELETE CASCADE,
  CONSTRAINT survey_question_logic_condition_type_check 
    CHECK (
      condition_type IN (
        'equals', 
        'not_equals', 
        'contains', 
        'greater_than', 
        'less_than'
      )
    )
);

-- Índices para mejorar performance
CREATE INDEX IF NOT EXISTS idx_survey_question_logic_question 
ON public.survey_question_logic (question_id) 
WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_survey_question_logic_target_section 
ON public.survey_question_logic (target_section_id);

-- Dar permisos (sin RLS)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.survey_question_logic TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.survey_question_logic TO authenticated;

-- Recargar schema cache
NOTIFY pgrst, 'reload schema';

-- Comentarios
COMMENT ON TABLE public.survey_question_logic IS 
'Tabla para configurar lógica condicional de saltos entre secciones basada en respuestas';

COMMENT ON COLUMN public.survey_question_logic.condition_type IS 
'Tipo de condición: equals, not_equals, contains, greater_than, less_than';

COMMENT ON COLUMN public.survey_question_logic.target_section_id IS 
'ID de la sección a la que se salta si se cumple la condición';
