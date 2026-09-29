"""Validate the saved egg asset's particle budget and fade curves offline."""
from pathlib import Path
import json
import xml.etree.ElementTree as E

root=Path(__file__).resolve().parents[2]
models=E.parse(root/'src/world/EggTemplates.rbxmx').findall('./Item/Item')
assert len(models)==6
expected=[12,14,15,19,24,18]
report=[]
for i,model in enumerate(models):
    name=model.find("Properties/string[@name='Name']").text
    parts=[n for n in model.findall('Item') if n.get('class') in ('Part','WedgePart')]
    effects=model.findall(".//Item[@class='ParticleEmitter']")
    rate=0
    for emitter in effects:
        p=emitter.find('Properties')
        rate+=float(p.find("float[@name='Rate']").text)
        assert float(p.find("float[@name='Rate']").text)<=7
        assert max(map(float,p.find("NumberRange[@name='Lifetime']").text.split()))<=2.2
        for key in ('Size','Transparency'):
            seq=list(map(float,p.find(f"NumberSequence[@name='{key}']").text.split()))
            assert len(seq)==12 and seq[0]==0 and seq[-3]==1
            assert seq[::3]==sorted(seq[::3])
        seq=list(map(float,p.find("NumberSequence[@name='Transparency']").text.split()))
        assert seq[1]==1 and seq[-2]==1
    assert len(parts)==expected[i] and 2<=len(effects)<=6 and rate<=32
    report.append(dict(egg=name,parts=len(parts),emitters=len(effects),particlesPerSecond=rate))
output=root/'assets/eggs/rectangular-v1/particle-audit.json'
output.write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report))
