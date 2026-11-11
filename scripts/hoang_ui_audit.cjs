// Read-only audit of user-facing language and pictographs in Flutter source.
const fs = require('node:fs');
const path = require('node:path');
const root = fs.existsSync(path.join(__dirname, '..', 'mobile', 'lib'))
  ? path.join(__dirname, '..', 'mobile', 'lib')
  : path.join(__dirname, '..', 'lib');
function files(dir){return fs.readdirSync(dir,{withFileTypes:true}).flatMap(x=>x.isDirectory()?files(path.join(dir,x.name)):x.name.endsWith('.dart')?[path.join(dir,x.name)]:[]);}
let eng=[],emoji=[];
const literal=/'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*"/g;
for(const file of files(root)){
 const code=fs.readFileSync(file,'utf8');
 for(const match of code.matchAll(literal)){
  const s=match[0].slice(1,-1);
  const line=code.slice(0,match.index).split('\n').length;
  if(/\p{Extended_Pictographic}/u.test(s))emoji.push({file:path.relative(root,file),line,text:s.slice(0,100)});
  if(/^[\x20-\x7e]+$/.test(s)&&/[A-Za-z]{3}/.test(s)&&/(?:\s[A-Za-z]{3}|^(?:Home|Plan|Nutrition|Profile|Dashboard|Loading|Retry|Error|Save|Create|View|Settings|Search|Role|USER|admin|Details|Your|From|Pending|Hello|Next|Back|Edit|Choose|Cancel)$)/i.test(s)){
    eng.push({file:path.relative(root,file),line,text:s.slice(0,130)});
  }
 }
}
process.stdout.write('VISIBLE-EMOJI-CANDIDATES '+emoji.length+'\n'+emoji.map(x=>JSON.stringify(x)).join('\n')+'\n');
process.stdout.write('ASCII-PHRASE-CANDIDATES '+eng.length+'\n'+eng.slice(0,170).map(x=>JSON.stringify(x)).join('\n')+'\n');

if (emoji.length > 0) process.exitCode = 1;
