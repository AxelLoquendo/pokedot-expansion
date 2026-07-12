#!/usr/bin/env node
import path from 'path';
import fs from 'fs';

const OUTPUT_DIR = import.meta.dirname;
const GEN = 3;
const re = /(?<=<a class="row" href="\.\/)[\w\d]+\.png(?=">)/gm;
let body;

const spritesGallery = `https://play.pokemonshowdown.com/sprites/gen${GEN}/`;
body = await fetch(spritesGallery).then(res => res.text());
const folderPath = path.join(OUTPUT_DIR, `gen${GEN}`);
fs.mkdirSync(folderPath, {recursive: true})


for (const pokemon of body.matchAll(re)) {
  console.log(pokemon[0]);

  const spriteUrl = spritesGallery + pokemon[0];
  const sprite = await fetch(spriteUrl).then(res => res.arrayBuffer());

  fs.writeFileSync(path.join(folderPath, pokemon[0]), Buffer.from(sprite));
}

const spritesBackGallery = `https://play.pokemonshowdown.com/sprites/gen${GEN}-back/`;
body = await fetch(spritesBackGallery).then(res => res.text());
const folderPathBack = path.join(OUTPUT_DIR, `gen${GEN}_back`);
fs.mkdirSync(folderPathBack, {recursive: true})

for (const pokemon of body.matchAll(re)) {
  console.log("back/" + pokemon[0]);

  const spriteUrl = spritesBackGallery + pokemon[0];
  const sprite = await fetch(spriteUrl).then(res => res.arrayBuffer());

  fs.writeFileSync(path.join(folderPathBack, pokemon[0]), Buffer.from(sprite));
}
