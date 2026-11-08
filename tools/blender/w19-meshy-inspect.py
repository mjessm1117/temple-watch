"""Print mesh dimensions and components of a Meshy pass-4 preview."""
import bpy
import sys
from mathutils import Vector
from collections import Counter, defaultdict

source = sys.argv[sys.argv.index('--') + 1]
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=source)
for obj in bpy.data.objects:
    if obj.type != 'MESH':
        continue
    points = [obj.matrix_world @ v.co for v in obj.data.vertices]
    low = [min(p[i] for p in points) for i in range(3)]
    high = [max(p[i] for p in points) for i in range(3)]
    print('MESHY_INSPECT', obj.name, 'verts', len(points), 'tris', sum(len(p.vertices)-2 for p in obj.data.polygons), 'bounds', tuple(round(x,3) for x in low), tuple(round(x,3) for x in high))
    # glTF seams split vertices; weld by position for meaningful loose-part counts.
    keys=[tuple(round(c,5) for c in p) for p in points]
    unique={key:i for i,key in enumerate(dict.fromkeys(keys))}
    welded=[unique[key] for key in keys]
    welded_points=list(unique)
    adjacency=[set() for _ in welded_points]
    for f in obj.data.polygons:
        vs=[welded[v] for v in f.vertices]
        for v in vs: adjacency[v].update(vs)
    seen=set(); groups=[]
    for v in range(len(welded_points)):
        if v in seen: continue
        todo=[v];seen.add(v); comp=[]
        while todo:
            u=todo.pop();comp.append(u)
            for n in adjacency[u]-seen:seen.add(n);todo.append(n)
        groups.append(comp)
    for comp in sorted(groups,key=len,reverse=True)[:20]:
        bounds=tuple((round(min(welded_points[v][i] for v in comp),3),round(max(welded_points[v][i] for v in comp),3)) for i in range(3))
        print('COMPONENT',len(comp),bounds)
    print('LOOSE_PARTS_AFTER_POSITION_WELD',len(groups))
    axis=2 if 'sniper' in source else 0
    hist=Counter(int(p[axis]*10)/10 for p in points)
    print('HIST',sorted(hist.items()))
