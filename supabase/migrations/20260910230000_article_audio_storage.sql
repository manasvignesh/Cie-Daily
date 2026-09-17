insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'article-audio',
  'article-audio',
  true,
  52428800,
  array['audio/wav']
)
on conflict (id) do update
set
  public = true,
  file_size_limit = 52428800,
  allowed_mime_types = array['audio/wav'];
