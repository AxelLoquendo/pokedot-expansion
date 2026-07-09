#!/usr/bin/env node
import path from 'path';
import fs from 'fs';

const OUTPUT_DIR = import.meta.dirname;
let body;

body = await fetch('https://play.pokemonshowdown.com/sprites/gen1/?view=sprites').then(res => res.text());

for (const pokemon of body.matchAll(/(?<=\<figure id=")\w+(?=\.png"\>)/g)) {
  console.log(pokemon[0]);

  const spriteUrl = 'https://play.pokemonshowdown.com/sprites/gen1/' + pokemon[0] + '.png';
  const sprite = await fetch(spriteUrl).then(res => res.arrayBuffer());

  fs.writeFileSync(path.join(OUTPUT_DIR, 'gen1', `${pokemon[0]}.png`), Buffer.from(sprite));
}


body = await fetch('https://play.pokemonshowdown.com/sprites/gen1-back/?view=sprites').then(res => res.text());

for (const pokemon of body.matchAll(/(?<=\<figure id=")\w+(?=\.png"\>)/g)) {
  console.log(pokemon[0]);

  const spriteUrl = 'https://play.pokemonshowdown.com/sprites/gen1-back/' + pokemon[0] + '.png';
  const sprite = await fetch(spriteUrl).then(res => res.arrayBuffer());

  fs.writeFileSync(path.join(OUTPUT_DIR, 'gen1_back', `${pokemon[0]}.png`), Buffer.from(sprite));
}
