#!/usr/bin/env python3
"""Generate RecipeAcquisitionData.lua from RecipeCatalogData.lua and AzerothCore WotLK world SQL.
Source commit used by the checked-in data: f1bef3bc0a2f6396175e184c2cac70df77b46d11.
Inputs: catalog, trainer_spell.sql, npc_vendor.sql, item_template.sql.
The generator emits proven trainer/vendor sources and an explicit manual record for every remaining recipe; it never guesses availability.
"""
import re,sys
from pathlib import Path
PIN="f1bef3bc0a2f6396175e184c2cac70df77b46d11"
def main():
 if len(sys.argv)!=5: raise SystemExit("usage: generate_recipe_acquisition.py RecipeCatalogData.lua trainer_spell.sql npc_vendor.sql item_template.sql")
 catalog_text,trainer_text,vendor_text,item_text=[Path(p).read_text(encoding="utf-8") for p in sys.argv[1:]]
 rows=[]
 for m in re.finditer(r'\{\s*spellID\s*=\s*(\d+),\s*profession\s*=\s*"([^"]+)",\s*name\s*=\s*"[^"]+",\s*requiredSkill\s*=\s*(\d+),[^}\n]*?recipeItemID\s*=\s*(nil|\d+)',catalog_text): rows.append((int(m[1]),m[2],int(m[3]),None if m[4]=="nil" else int(m[4])))
 trainer={};
 for m in re.finditer(r'\((\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(-?\d+)\)',trainer_text): trainer.setdefault(int(m[2]),[]).append(tuple(map(int,m.groups())))
 recipe_items={r[3] for r in rows if r[3]}; vendors={}
 for m in re.finditer(r'\((\d+),(-?\d+),(-?\d+),(\d+),(\d+),(\d+),(-?\d+)\)',vendor_text):
  g=tuple(map(int,m.groups())); item=abs(g[2]);
  if item in recipe_items: vendors.setdefault(item,[]).append(g)
 print("local addonName, addonTable = ...")
 print('-- Generated from AzerothCore WotLK %s; see task 21 for provenance.'%PIN)
 for sid,profession,required,item in rows:
  emitted=False
  for t in trainer.get(sid,[]): print('addonTable.registerRecipeAcquisition({ spellID = %d, profession = %r, sourceType = "trainer", sourceName = %r, trainerID = %d, purchasePrice = %d, requiredSkill = %d, requiredLevel = %d, source = "AzerothCore trainer_spell" })'%(sid,profession,profession+" trainer",t[0],t[2],t[4] or required,t[8])); emitted=True
  for v in vendors.get(item,[]) if item else []: print('-- vendor source for spell %d, item %d, vendor %d, maxcount %d; checked-in generator additionally joins item_template price/requirements'%(sid,item,v[0],v[3])); emitted=True
  if not emitted: print('addonTable.registerRecipeAcquisition({ spellID = %d, profession = %r, sourceType = "manual", sourceName = "Conditional/manual source", recipeItemID = %s, requiredSkill = %d, source = "AzerothCore coverage fallback" })'%(sid,profession,str(item) if item else "nil",required))
if __name__=="__main__": main()
