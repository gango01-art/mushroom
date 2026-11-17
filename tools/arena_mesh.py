"""Authored shallow water using a native Hammer mesh schema."""
from pathlib import Path
import math,uuid
from vendor import datamodel as dm
ROOT=Path(__file__).resolve().parents[1]
def mesh(model,name,origin,points,faces,material,uv_for_face=None):
 world=model.root['world'];e=next((e for e in world['children'] if e.name==name),None);created=e is None
 if e is None:
  template=dm.load(str(ROOT/'tools/templates/valve_water_mesh.dmx'));memo={}
  def clone(src):
   if src is None:return None
   key=str(src.id)
   if key in memo:return memo[key]
   out=model.add_element(src.name,src.type,id=uuid.uuid5(uuid.NAMESPACE_URL,'duality/mesh/'+name+'/'+key));memo[key]=out
   for k,v in src.items():
    if isinstance(v,dm.Element):out[k]=clone(v)
    elif isinstance(v,dm._ElementArray):out[k]=dm.make_array([clone(a)for a in v],dm.Element)
    else:out[k]=v
   return out
  e=clone(template.root);e.name=name;world['children'].append(e)
 if created:e['nodeID']=max(v.get('nodeID',0)for v in model.elements)+1
 e['origin']=dm.Vector3(origin);e['angles']=dm.Angle([0,0,0]);e['scales']=dm.Vector3([1,1,1])
 data=e['meshData'];data['materials']=dm.make_array([material],str)
 edges=[];lookup={};face_edges=[];nexts=[]
 for fi,face in enumerate(faces):
  start=len(edges);face_edges.append(start)
  for j,u in enumerate(face):
   v=face[(j+1)%len(face)];assert (u,v)not in lookup
   lookup[u,v]=len(edges);edges.append((u,v,fi));nexts.append(start+(j+1)%len(face))
 for u,v,fi in list(edges):
  if (v,u)not in lookup:lookup[v,u]=len(edges);edges.append((v,u,-1));nexts.append(-1)
 ghost={u:i for i,(u,v,fi)in enumerate(edges)if fi<0}
 for i,(u,v,fi)in enumerate(edges):
  if fi<0:nexts[i]=ghost[v]
 vertex_edges=[next(i for i,(u,v,fi)in enumerate(edges)if u==j)for j in range(len(points))]
 pairs={};edge_data=[]
 for u,v,fi in edges:
  key=tuple(sorted((u,v)))
  if key not in pairs:pairs[key]=len(pairs)
  edge_data.append(pairs[key])
 arrays={'vertexEdgeIndices':vertex_edges,'vertexDataIndices':list(range(len(points))),
 'edgeVertexIndices':[v for u,v,fi in edges],'edgeOppositeIndices':[lookup[v,u]for u,v,fi in edges],
 'edgeNextIndices':nexts,'edgeFaceIndices':[fi for u,v,fi in edges], 'edgeDataIndices':edge_data,
 'edgeVertexDataIndices':list(range(len(edges))), 'faceEdgeIndices':face_edges,'faceDataIndices':list(range(len(faces)))}
 for k,v in arrays.items():data[k]=dm.make_array(v,int)
 for key,size in [('vertexData',len(points)),('faceVertexData',len(edges)),('edgeData',len(pairs)),('faceData',len(faces))]:
  data[key]['size']=size
 for st in data['vertexData']['streams']:st['data']=dm.make_array([dm.Vector3(p)for p in points],dm.Vector3)
 normals=[]
 for face in faces:
  a,b,c=[points[j]for j in face[:3]];u=[b[j]-a[j]for j in range(3)];v=[c[j]-a[j]for j in range(3)]
  n=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]];length=math.sqrt(sum(t*t for t in n));normals.append([t/length for t in n])
 for st in data['faceVertexData']['streams']:
  values=[];kind=st['semanticName']
  for u,v,fi in edges:
   p=points[v];n=normals[fi]if fi>=0 else[0,0,0]
   if uv_for_face and fi>=0:uv=uv_for_face(v,fi)
   else:uv=[p[0]/512,p[1]/512]if abs(n[2])>.8 else[(p[0]+p[1])/128,p[2]/128]
   values.append(dm.Vector2(uv)if kind=='texcoord' else dm.Vector3(n)if kind=='normal' else dm.Vector4([1,0,0,-1]))
  st['data']=dm.make_array(values,type(values[0]))
 for st in data['edgeData']['streams']:st['data']=dm.make_array([0]*len(pairs),int)
 for st in data['faceData']['streams']:
  value=st['data'][0];st['data']=dm.make_array([value for _ in faces],type(value))
 data['subdivisionData']['subdivisionLevels']=dm.make_array([0]*len(edges),int)
 return e

def water(model):
    """Continuous water surface with a shallow rim under the visual boundary."""
    segments = 128
    rings = [(874, 4), (890, 2), (900, -1)]
    points = [[r*math.cos(i*math.tau/segments), r*math.sin(i*math.tau/segments), z]
              for r, z in rings for i in range(segments)]
    faces = [list(range(segments))]
    for ring in range(len(rings)-1):
        start = ring * segments
        for i in range(segments):
            current = start+i
            following = start+(i+1)%segments
            faces.append([current, current+segments, following+segments, following])
    return mesh(model, 'rift_shallow_water', [0,0,128], points, faces,
                'maps/summer_assets/water/water_summer_000.vmat')

def center_barrier(model, radius=900, height=52):
    segments = 128
    points = [[radius*math.cos(i*math.tau/segments), radius*math.sin(i*math.tau/segments), z]
              for z in (1, height+1) for i in range(segments)]
    faces = [(i, (i+1)%segments, segments+(i+1)%segments, segments+i) for i in range(segments)]

    def uv(vertex, face):
        edge = vertex % segments
        if edge == 0 and face == segments-1:
            edge = segments
        return [8*edge/segments, 0.992 if vertex < segments else 0.008]

    wall = mesh(model, 'rift_center_veil', [0,0,128], points, faces,
                'materials/duality/center_veil.vmat', uv)
    wall['physicsType'] = 'none'
    wall['bakelighting'] = False
    wall['renderToCubemaps'] = False
    return wall
