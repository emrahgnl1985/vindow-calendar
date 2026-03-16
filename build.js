const fs = require('fs');

const url  = process.env.SUPABASE_URL  || '';
const anon = process.env.SUPABASE_ANON || '';

if (!url || !anon) {
  console.warn('⚠  SUPABASE_URL or SUPABASE_ANON env var is not set — app will not authenticate.');
}

fs.writeFileSync(
  'supabase-config.js',
  `const SUPABASE_URL  = '${url}';\nconst SUPABASE_ANON = '${anon}';\n`
);

console.log('✓ supabase-config.js generated from environment variables.');
