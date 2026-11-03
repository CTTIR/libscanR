"""Independent 50-digit forward model for fictional X/Y LTE regression data.

No NIST transitions or experimental measurements are represented by this fixture.
The analytical result is T=10000 K, number fractions X=.7/Y=.3, ne=1e17 cm^-3.
"""
from decimal import Decimal as D, getcontext
import csv,json
from pathlib import Path
getcontext().prec=50
pi=D('3.1415926535897932384626433832795028841971693993751')
k=D('1.380649e-23');h=D('6.62607015e-34');me=D('9.1093837139e-31');ev=D('1.602176634e-19')
T=D('10000');ne=D('1e17');k_ev=k/ev;F=D('1e-6')
config={'X':(D('.7'),D('7'),D('2'),D('3'),1),'Y':(D('.3'),D('9'),D('4'),D('5'),2)}
rows=[];gold={'temperature_k':float(T),'electron_density':float(ne),'fractions':{'X':.7,'Y':.3},'ion_ratios':{}}
for el,wavelengths,energies,weights,rates,responses in [
 ('X',[520,530,540],['2','3','4'],[1,3,5],['1e7','2e7','5e7'],['.5','1.1','1.3']),
 ('Y',[560,570,580],['2.2','3.4','4.5'],[2,4,6],['3e7','1e7','4e7'],['2.4','1.7','.8'])]:
 fraction,chi,u0,u1,stage=config[el]
 q=2*(2*pi*me*k*T/(h*h))**D('1.5')/(ne*D('1e6'))*(u1/u0)*(-chi/(k_ev*T)).exp()
 gold['ion_ratios'][el]=float(q)
 stage_fraction=(1/(1+q)) if stage==1 else q/(1+q)
 partition=u0 if stage==1 else u1
 for wl,E,g,A,response in zip(wavelengths,energies,weights,rates,responses):
  photons=F*fraction*stage_fraction/partition*D(g)*D(A)*(-D(E)/(k_ev*T)).exp()*D(response)
  energy=photons/(D(wl)*D('1e-9'))
  rows.append(dict(element=el,ionization=stage,wavelength_nm=wl,wavelength_medium='vacuum',
    wavelength_vacuum_nm=wl,A_s=float(D(A)),g_upper=g,energy_upper_ev=float(E),response=float(response),
    source='Fictional analytical regression fixture; not measured or NIST data',
    integrated_energy=format(energy,'.30g'),integrated_photon=format(photons,'.30g')))
p=Path(__file__).resolve().parents[4]/'inst/extdata/saha_synthetic_lines.csv'
with p.open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=list(rows[0]),lineterminator="\n");w.writeheader();w.writerows(rows)
Path(__file__).with_name('golden.json').write_text(json.dumps(gold,indent=2)+'\n')
print(p)
