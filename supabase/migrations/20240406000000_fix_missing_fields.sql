
-- Add rating fields to tasks table if they don't exist
ALTER TABLE public.tasks
ADD COLUMN IF NOT EXISTS is_requestor_rated BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS is_doer_rated BOOLEAN DEFAULT FALSE;

-- Create storage bucket for chat attachments if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
SELECT 'chat_attachments', 'chat_attachments', true
WHERE NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'chat_attachments');

-- Set storage policies for chat attachments
CREATE POLICY IF NOT EXISTS "Allow public read access"
ON storage.objects FOR SELECT
USING (bucket_id = 'chat_attachments');

CREATE POLICY IF NOT EXISTS "Allow authenticated users to upload files"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'chat_attachments' AND auth.role() = 'authenticated');

CREATE POLICY IF NOT EXISTS "Allow users to update their own files"
ON storage.objects FOR UPDATE
USING (bucket_id = 'chat_attachments' AND auth.uid() = owner);

CREATE POLICY IF NOT EXISTS "Allow users to delete their own files"
ON storage.objects FOR DELETE
USING (bucket_id = 'chat_attachments' AND auth.uid() = owner);

-- Enable realtime for tasks to track deadline expirations
ALTER TABLE public.tasks REPLICA IDENTITY FULL;
ALTER PUBLICATION supabase_realtime ADD TABLE public.tasks;
