-- ============================================================
-- Migration: 005_add_survey_question_logic.sql
-- Version: 6
-- Description: Agrega lógica condicional a preguntas de encuestas
-- Date: 2024-12-20
-- Author: GestionArte Team
-- ============================================================

-- Agregar columnas para lógica condicional en survey_questions
ALTER TABLE public.survey_questions 
ADD COLUMN IF NOT EXISTS show_if_question_id uuid,
ADD COLUMN IF NOT EXISTS show_if_response_value integer,
ADD COLUMN IF NOT EXISTS show_if_response_text text;

-- Agregar constraint para la lógica condicional
ALTER TABLE public.survey_questions
ADD CONSTRAINT survey_questions_show_if_question_fkey 
FOREIGN KEY (show_if_question_id) 
REFERENCES public.survey_questions(question_id)
ON DELETE SET NULL;

-- Agregar índices para mejorar performance
CREATE INDEX IF NOT EXISTS idx_survey_questions_show_if 
ON public.survey_questions(show_if_question_id);

-- Comentarios
COMMENT ON COLUMN public.survey_questions.show_if_question_id IS 
'ID de la pregunta de la cual depende esta pregunta (lógica condicional)';

COMMENT ON COLUMN public.survey_questions.show_if_response_value IS 
'Valor de respuesta que debe tener la pregunta padre para mostrar esta pregunta';

COMMENT ON COLUMN public.survey_questions.show_if_response_text IS 
'Texto de respuesta que debe tener la pregunta padre para mostrar esta pregunta';

-- ============================================================
-- FIN DE MIGRACIÓN 005
-- ============================================================
