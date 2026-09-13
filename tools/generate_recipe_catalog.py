#!/usr/bin/env python3
"""Generate RecipeCatalogData.lua from AtlasLootClassic commit 8e99341e4e779328460bf7684c0d5b22ce50ddf1."""
import re,sys
from pathlib import Path
PROF={1:"First Aid",2:"Blacksmithing",3:"Leatherworking",4:"Alchemy",6:"Cooking",8:"Tailoring",9:"Engineering",10:"Enchanting",14:"Jewelcrafting",15:"Inscription"}
PIN="8e99341e4e779328460bf7684c0d5b22ce50ddf1"
def sec(t,a,b): x=t.index(a); y=t.find(b,x+1); return t[x:] if y<0 else t[x:y]
def main():
 if len(sys.argv)!=3: raise SystemExit("usage: generate_recipe_catalog.py Profession.lua Recipe.lua")
 p=Path(sys.argv[1]).read_text(encoding="utf-8"); q=Path(sys.argv[2]).read_text(encoding="utf-8"); recipes={}; items={}
 for a,b in [("PROFESSION_DATA.CLASSIC","PROFESSION_DATA.BCC"),("PROFESSION_DATA.BCC","PROFESSION_DATA.WRATH"),("PROFESSION_DATA.WRATH","PROFESSION_DATA.CATA")]:
  for line in sec(p,a,b).splitlines():
   m=re.match(r"^\s*\[(\d+)\]\s*=\s*\{(nil|\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*\{([^}]*)\},\s*\{([^}]*)\}(?:,\s*(\d+))?\s*\}",line)
   if not m: continue
   sid,pid=int(m[1]),int(m[3]);
   if pid not in PROF or sid>=100000: continue
   ids=[int(x) for x in m[7].split(",") if x.strip()]; counts=[int(x) for x in m[8].split(",") if x.strip()]
   if len(ids)!=len(counts): raise ValueError("reagent mismatch %d"%sid)
   recipes[sid]=(None if m[2]=="nil" else int(m[2]),PROF[pid],int(m[4]),list(zip(ids,counts)),int(m[9] or 1))
 for a,b in [("RECIPE_DATA.CLASSIC","RECIPE_DATA.BCC"),("RECIPE_DATA.BCC","RECIPE_DATA.WRATH"),("RECIPE_DATA.WRATH","RECIPE_DATA.CATA")]:
  for line in sec(q,a,b).splitlines():
   m=re.match(r"^\s*\[(\d+)\]\s*=\s*\{(\d+),\s*(\d+),\s*(\d+)\}",line)
   if m and int(m[2]) in PROF and int(m[4])<100000: items[int(m[4])]=int(m[1])
 print("local addonName, addonTable = ...\n"); print("-- Generated from AtlasLootClassic commit %s; do not hand-edit."%PIN); print('addonTable.recipeCatalogProvenance = { source = "Hoizame/AtlasLootClassic", commit = "%s", gameVersion = "Wrath of the Lich King 3.3.5", recordCount = %d }'%(PIN,len(recipes))); print("addonTable.registerRecipeCatalogBatch({")
 for sid,(output,profession,required,reagents,quantity) in sorted(recipes.items()):
  rr=", ".join("{ itemID = %d, count = %d }"%x for x in reagents); oi="nil" if output is None else str(output); ri=str(items[sid]) if sid in items else "nil"; print("    { spellID = %d, profession = %r, name = \"Spell %d\", requiredSkill = %d, outputItemID = %s, outputQuantity = %d, recipeItemID = %s, reagents = { %s } },"%(sid,profession,sid,required,oi,quantity,ri,rr))
 print("})")
if __name__=="__main__": main()
