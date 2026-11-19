// Brainrot Bay — the entrypoint that hands the game in.
//
// Build the place first, then run this:
//   rojo build default.project.json --output game.rbxl
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
//
// This program copies game.rbxl, PLAY.json, src/ and screenshots/ into the
// output directory and writes dossier.json there with the vendored make.fun
// library, so the gate can read the place and its scripts.
//
// It runs in a fresh container with no network and a 15 second limit, on the
// standard library only, and it must write the same bytes on both runs.
// Every name under the output starts with a letter, a digit or _, and holds
// only letters, digits, . _ and - — so nothing whose name starts with a dot
// (a .gitkeep, a .DS_Store) is ever copied in, or the gate refuses the entry.
//
// Outside the grader, MAKEFUN_OUTPUT_DIR stands in for /output.

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const root = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

// Keep dotfiles out of the entry: the gate fails an output that holds one.
function visible(path: string): boolean {
  return !basename(path).startsWith('.');
}

function stageFiles(): void {
  mkdirSync(out, { recursive: true });
  copyFileSync(join(root, 'game.rbxl'), join(out, 'game.rbxl'));
  copyFileSync(join(root, 'PLAY.json'), join(out, 'PLAY.json'));
  cpSync(join(root, 'src'), join(out, 'src'), { recursive: true, filter: visible });
  if (existsSync(join(root, 'screenshots'))) {
    cpSync(join(root, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: visible });
  }
}

function stageDossier(): void {
  // These caps mirror the scorer's own: only the text cap shapes the bytes,
  // the rest refuse an entry the scorer would refuse anyway (too many
  // screenshots, one over 256 KiB, a place past its instance or script caps).
  const dossier = buildDossier(out, {
    text_max_bytes: 65536,
    screenshots: { max: 4, max_bytes: 262144 },
    max_instances: 500000,
    scripts_max_source_bytes: 8388608,
    scripts_max_path_chars: 1048576,
  });
  writeFileSync(join(out, 'dossier.json'), dossier);
}

stageFiles();
stageDossier();
