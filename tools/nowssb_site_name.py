from pathlib import Path

path = Path(__file__).resolve().parents[1] / 'index.html'
s = path.read_text(encoding='utf-8')
s = s.replace('<link rel="canonical" href="https://nowssb.com/">', '<link rel="canonical" href="https://nowssb.com/">\n<link rel="sitemap" type="application/xml" href="/sitemap.xml">', 1)
s = s.replace('"name":"NowssB",\n      "url":"https://nowssb.com/",', '"name":"NowssB",\n      "alternateName":"NowssB by NOWSSBANSIU",\n      "url":"https://nowssb.com/",', 1)
s = s.replace('"name":"NowssB",\n      "url":"https://nowssb.com/",', '"name":"NowssB",\n      "alternateName":"NowssB by NOWSSBANSIU",\n      "url":"https://nowssb.com/",', 1)
s = s.replace('"operatingSystem":"Web, Android",\n      "publisher":', '"operatingSystem":"Web, Android",\n      "brand":{"@type":"Brand","name":"NowssB"},\n      "publisher":', 1)
path.write_text(s, encoding='utf-8')
print('Added exact NowssB site-name signals to the homepage.')
