// Patches build/web static branding (tab title, PWA name, description) to match
// the built brand. Run via scripts/apply_web_brand.sh <phh|hca>.
const fs = require('fs');
const brand = process.argv[2] || 'phh';
const name = brand === 'hca' ? 'HomeCloudAsia' : 'PHH Housing';
const desc = `${name} — community management.`;

let m = fs.readFileSync('build/web/manifest.json', 'utf8');
m = m
  .replace(/"name":\s*"[^"]*"/, `"name": "${name}"`)
  .replace(/"short_name":\s*"[^"]*"/, `"short_name": "${name}"`)
  .replace(/"description":\s*"[^"]*"/, `"description": "${desc}"`);
fs.writeFileSync('build/web/manifest.json', m);

let h = fs.readFileSync('build/web/index.html', 'utf8');
h = h
  .replace(/<title>[^<]*<\/title>/, `<title>${name}</title>`)
  .replace(/(apple-mobile-web-app-title" content=")[^"]*(")/, `$1${name}$2`)
  .replace(/(name="description" content=")[^"]*(")/, `$1${desc}$2`);
fs.writeFileSync('build/web/index.html', h);

console.log(`web branding applied: ${brand} (${name})`);
