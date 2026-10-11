"""Geometry/UV equivalence, item transforms, face directions and 1.21.8 checks."""
from pathlib import Path
import json,sys,copy
import numpy as np
import generate_umbrella_smooth as g
STAGE=Path(sys.argv[1]);report={};worst=0
MC_CORNERS=json.loads((Path(__file__).parent/'minecraft_face_corners_1_21_8.json').read_text())
def check_client_uv(e):
    """Independent official FaceInfo / BlockElementFace vertex convention.
    This catches reversed 90/270 turns that self-comparison missed in v3.
    """
    coords=dict(zip('xyzXYZ',e['from']+e['to']))
    intended={side:(p,np.array(uv)/16) for side,p,uv,t in g.quad_faces(e)}
    for side,f in e['faces'].items():
        points=np.array([[coords[c] for c in corner] for corner in MC_CORNERS[side]],float)
        r=e.get('rotation')
        if r:points=(points-r['origin'])@g.rot(r['axis'],r['angle']).T+r['origin']
        u,v,U,V=f['uv'];corners=np.array([[u,v],[u,V],[U,V],[U,v]])/16
        uv=np.array([corners[(i+f.get('rotation',0)//90)%4] for i in range(4)])
        a=np.c_[points,uv];b=np.c_[*intended[side]]
        distance=np.linalg.norm(a[:,None,:]-b[None,:,:],axis=2)
        assert float(distance.min(axis=1).max())<1e-6,(e.get('name'),side,'Minecraft UV mismatch')
def signature(groups):
    out=[]
    for label,phi,els in groups:
        center=np.array([8.,8.,8.]) if label=='shaft' else g.CENTER
        q=g.rot('y',phi)
        for e in els:
            for side,v,uv,tex in g.quad_faces(e):
                points=(v-8)@q.T+center
                out.append((tex,tuple(sorted(tuple(np.round(np.r_[p,u],4)) for p,u in zip(points,uv)))))
    return sorted(out)
raw=g.build()
for name,groups in raw.items():
    assert signature(groups)==signature(g.compact(groups)),name+' baking changed geometry/UV'
    item=json.loads((STAGE/'items'/f'{name}.json').read_text())
    baseline=g.display_base(name)
    total=0;faces=0
    for part,(label,phi,els) in zip(item['model']['models'],g.compact(groups)):
        path=STAGE/'models'/(part['model'].removeprefix(g.PREFIX)+'.json')
        model=json.loads(path.read_text());assert model['elements']==els
        center=g.CENTER.copy()
        if name=='umbrella_canopy':center+=g.CANOPY_SHIFT
        for e in model['elements']:
            check_client_uv(e)
            f=np.array(e['from']);t=np.array(e['to']);assert np.all(t>=f)
            assert min(f)>=-16 and max(t)<=32,(name,f,t)
            r=e.get('rotation',{});assert abs(r.get('angle',0))<=45
            assert set(r)<=set(['axis','angle','origin','rescale'])
            for v in e['faces'].values():
                assert min(v['uv'])>=0 and max(v['uv'])<=16
                assert v.get('rotation',0) in [0,90,180,270]
                assert 'cullface' not in v
            if e.get('shade') is False:assert len(e['faces'])==2
            for side,points,uv,texture in g.quad_faces(e):
                world=(points-8)@g.rot('y',phi).T+center
                for slot in g.SLOTS:
                    mirror=np.diag([-1,1,1]) if 'lefthand' in slot else np.eye(3)
                    base=baseline.get(slot,{});d=model['display'][slot]
                    rb=mirror@g.xyz(base.get('rotation',[0,0,0]))@mirror
                    actualr=mirror@g.xyz(d['rotation'])@mirror
                    expected=(world-8)@rb.T*np.array(base.get('scale',[1,1,1]))+mirror@base.get('translation',[0,0,0])
                    actual=((points-8)*np.array(d['scale']))@actualr.T+mirror@d['translation']
                    error=float(np.max(abs(expected-actual)));worst=max(worst,error)
                    assert error<2e-5,(name,slot,error)
            total+=1;faces+=len(e['faces'])
    report[name]={'elements':total,'faces':faces,'composite_parts':len(item['model']['models']),'single_axis_within_45':True,'positive_extents':True,'geometry_and_uv_preserved_by_baking':True,'eight_display_contexts_verified':True,'minecraft_1_21_8_uv_convention_verified':True}
report['max_display_error_model_units']=worst
report['runtime_client_test']='not performed'
(STAGE.parent/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
