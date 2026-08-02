// Syntax-check CfxLua by normalising the CitizenFX extensions into standard Lua
// before handing the result to luaparse. Structural mistakes (an unmatched `end`, a
// stray `)`, a truncated block) survive the normalisation, while the extensions
// themselves are neutralised so they don't report as false positives.
//
//   bun check.js <file|directory...>     defaults to ../../resources
import { parse } from 'luaparse';
import { readFileSync, readdirSync, statSync } from 'fs';
import { join, resolve } from 'path';

const SKIP_DIRS = new Set(['node_modules', 'dist', 'build', '.git', 'ui']);

// Backticks are hash literals only OUTSIDE strings. Inside a string a backtick is a
// quoted SQL identifier (`Char`, `key`, `default`) and has to be left alone.
function replaceHashLiterals(src) {
	let out = '';
	let i = 0;

	while (i < src.length) {
		const c = src[i];

		if (src.startsWith('[[', i)) {
			const close = src.indexOf(']]', i + 2);
			const end = close === -1 ? src.length : close + 2;
			out += src.slice(i, end);
			i = end;
			continue;
		}

		if (src.startsWith('--', i)) {
			const nl = src.indexOf('\n', i);
			const end = nl === -1 ? src.length : nl;
			out += src.slice(i, end);
			i = end;
			continue;
		}

		if (c === '"' || c === "'") {
			const quote = c;
			let j = i + 1;
			while (j < src.length) {
				if (src[j] === '\\') j += 2;
				else if (src[j] === quote) break;
				else j++;
			}
			out += src.slice(i, j + 1);
			i = j + 1;
			continue;
		}

		if (c === '`') {
			const close = src.indexOf('`', i + 1);
			if (close !== -1) {
				out += `"${src.slice(i + 1, close)}"`;
				i = close + 1;
				continue;
			}
		}

		out += c;
		i++;
	}

	return out;
}

function normalise(src) {
	return (
		replaceHashLiterals(src)
			// set-constructor shorthand:  { .house, .office }  ->  { house = true, office = true }
			.replace(/^(\s*)\.(\w+)(\s*,?)\s*$/gm, '$1$2 = true$3')
			// destructuring:  local SID, VIN in data  ->  local SID, VIN = data.SID, data.VIN
			.replace(/^(\s*)local\s+([\w\s,]+?)\s+in\s+([\w.\[\]"']+)\s*$/gm, (m, indent, names, source) => {
				const list = names.split(',').map((n) => n.trim());
				return `${indent}local ${list.join(', ')} = ${list.map((n) => `${source}.${n}`).join(', ')}`;
			})
			// compound assignment, statement form only, target may contain method calls
			.replace(/^(\s*)([\w.:\[\]"'()]+?)\s*([+\-*/])=\s*(.+)$/gm, '$1$2 = $2 $3 $4')
			// Lua 5.4 attributes:  local x <close> = ...  ->  local x = ...
			.replace(/<\s*(close|const)\s*>/g, '')
			// safe navigation and safe index
			.replace(/\?\./g, '.')
			.replace(/\?\[/g, '[')
	);
}

function collect(target, found) {
	let stats;
	try {
		stats = statSync(target);
	} catch {
		return found;
	}

	if (stats.isFile()) {
		if (target.endsWith('.lua')) found.push(target);
		return found;
	}

	for (const entry of readdirSync(target)) {
		if (entry.startsWith('.') || SKIP_DIRS.has(entry)) continue;
		collect(join(target, entry), found);
	}

	return found;
}

const args = process.argv.slice(2);
const targets = args.length > 0 ? args : [resolve(import.meta.dir, '../../resources')];

const files = [];
for (const target of targets) collect(target, files);

let failed = 0;
for (const file of files) {
	let src;
	try {
		src = readFileSync(file, 'utf8');
	} catch {
		continue;
	}

	try {
		parse(normalise(src), { luaVersion: '5.3' });
	} catch (err) {
		failed++;
		console.log(`FAIL ${file}`);
		console.log(`     ${err.message}`);
	}
}

console.log(`checked ${files.length} files, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
