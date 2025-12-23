-- ============================================================
-- Migration: 005_add_form_field_conditional_logic.sql
-- Version: 5
-- Description: Agrega lógica condicional a campos de formularios
-- Date: 2024-12-23
-- Author: GestionArte Team
-- ============================================================

-- ============================================================
-- AGREGAR COLUMNAS DE LÓGICA CONDICIONAL
-- ============================================================

-- Agregar columnas para lógica condicional en form_fields
ALTER TABLE public.form_fields
ADD COLUMN IF NOT EXISTS show_if_field_id uuid,
ADD COLUMN IF NOT EXISTS show_if_value text;

-- Agregar Foreign Key (si no existe)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'form_fields_show_if_field_id_fkey'
    ) THEN
        ALTER TABLE public.form_fields
        ADD CONSTRAINT form_fields_show_if_field_id_fkey 
        FOREIGN KEY (show_if_field_id) 
        REFERENCES public.form_fields(field_id) 
        ON DELETE SET NULL;
    END IF;
END $$;

-- Crear índice para mejorar performance
CREATE INDEX IF NOT EXISTS idx_form_fields_show_if_field_id 
ON public.form_fields(show_if_field_id) 
WHERE show_if_field_id IS NOT NULL;

-- Comentarios de documentación
COMMENT ON COLUMN public.form_fields.show_if_field_id IS 
'ID del campo SELECT/RADIO cuyo valor determina si este campo se muestra. NULL = siempre se muestra';

COMMENT ON COLUMN public.form_fields.show_if_value IS 
'Valor que debe tener el campo padre (show_if_field_id) para que este campo se muestre. Debe coincidir con option_value del catálogo';

-- ============================================================
-- FIN DE MIGRACIÓN 005
-- ============================================================
