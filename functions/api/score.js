export async function onRequestPost(context) {
  const { request, env } = context;
  const formData = await request.formData();
  const word = (formData.get('word') || '').trim();
  const audioFile = formData.get('audio');
  const dialect = (formData.get('dialect') || 'en-us').trim();

  if (!word || !(audioFile instanceof File)) {
    return Response.json({ error: 'word and audio are required' }, { status: 400 });
  }
  if (!env.SPEECHACE_API_KEY) {
    return Response.json({ error: 'Scoring is not configured yet' }, { status: 503 });
  }

  const target = `https://api.speechace.co/api/scoring/text/v9/json?key=${encodeURIComponent(env.SPEECHACE_API_KEY)}&dialect=${encodeURIComponent(dialect)}&user_id=nowssb_user`;
  const proxyForm = new FormData();
  proxyForm.append('text', word);
  proxyForm.append('user_audio_file', audioFile, audioFile.name || 'attempt.webm');

  const upstream = await fetch(target, { method: 'POST', body: proxyForm });
  const result = await upstream.json();
  if (!upstream.ok) {
    return Response.json({ error: 'Scoring failed', detail: result }, { status: 502 });
  }

  const scoredWord = result.text_score?.word_score_list?.[0];
  const simplified = {
    overallScore: scoredWord?.quality_score ?? null,
    phonemes: (scoredWord?.phone_score_list || []).map((phoneme) => ({
      sound: phoneme.phone,
      score: phoneme.quality_score,
      weak: Number(phoneme.quality_score) < 60,
    })),
  };
  return Response.json(simplified);
}

export async function onRequestOptions() {
  return new Response(null, { headers: { Allow: 'POST, OPTIONS' } });
}
