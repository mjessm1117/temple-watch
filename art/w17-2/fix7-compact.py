"""Remove unreferenced animation accessors and their bytes from Fix 6 GLBs."""
import json
import struct
from pathlib import Path

for path in sorted(Path('godot/assets/units/w17').glob('*.glb')):
    raw = path.read_bytes()
    magic, version, _ = struct.unpack_from('<4sII', raw)
    assert (magic, version) == (b'glTF', 2)
    json_length, json_type = struct.unpack_from('<I4s', raw, 12)
    assert json_type == b'JSON'
    doc = json.loads(raw[20:20 + json_length])
    bin_at = 20 + json_length
    bin_length, bin_type = struct.unpack_from('<I4s', raw, bin_at)
    assert bin_type == b'BIN\0'
    binary = raw[bin_at + 8:bin_at + 8 + bin_length]
    used = set()
    for animation in doc.get('animations', []):
        for sampler in animation['samplers']:
            used.update((sampler['input'], sampler['output']))
    for mesh in doc['meshes']:
        for primitive in mesh['primitives']:
            used.update(primitive['attributes'].values())
            if 'indices' in primitive:
                used.add(primitive['indices'])
            for target in primitive.get('targets', []):
                used.update(target.values())
    for skin in doc.get('skins', []):
        if 'inverseBindMatrices' in skin:
            used.add(skin['inverseBindMatrices'])
    mapping = {old: new for new, old in enumerate(sorted(used))}
    old_views = doc['bufferViews']
    old_accessors = doc['accessors']
    new_binary = bytearray()
    new_views = []
    view_map = {}
    def append(payload):
        offset = len(new_binary)
        new_binary.extend(payload)
        new_binary.extend(b'\0' * (-len(new_binary) % 4))
        return offset
    # Keep mesh and image views as whole blocks. Repack the animation view
    # accessor by accessor, dropping the orphaned keyframes.
    animation_views = {old_accessors[index]['bufferView'] for animation in doc.get('animations', [])
                       for sampler in animation['samplers'] for index in (sampler['input'], sampler['output'])}
    other_views = {old_accessors[index]['bufferView'] for index in used
                   if index not in {value for animation in doc.get('animations', [])
                                    for sampler in animation['samplers']
                                    for value in (sampler['input'], sampler['output'])}}
    for index, view in enumerate(old_views):
        if index in animation_views and index not in other_views:
            continue
        start = view.get('byteOffset', 0)
        offset = append(binary[start:start + view['byteLength']])
        view_map[index] = len(new_views)
        new_views.append({**view, 'byteOffset': offset})
    component_bytes = {5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4}
    dimensions = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}
    accessors = []
    for old in sorted(used):
        accessor = dict(old_accessors[old])
        view_index = accessor['bufferView']
        if view_index not in view_map:
            view = old_views[view_index]
            length = accessor['count'] * component_bytes[accessor['componentType']] * dimensions[accessor['type']]
            start = view.get('byteOffset', 0) + accessor.get('byteOffset', 0)
            offset = append(binary[start:start + length])
            accessor['bufferView'] = len(new_views)
            accessor.pop('byteOffset', None)
            new_views.append({'buffer': 0, 'byteOffset': offset, 'byteLength': length})
        else:
            accessor['bufferView'] = view_map[view_index]
        accessors.append(accessor)
    doc['accessors'] = accessors
    doc['bufferViews'] = new_views
    for animation in doc.get('animations', []):
        for sampler in animation['samplers']:
            sampler['input'] = mapping[sampler['input']]
            sampler['output'] = mapping[sampler['output']]
    for mesh in doc['meshes']:
        for primitive in mesh['primitives']:
            primitive['attributes'] = {key: mapping[value] for key, value in primitive['attributes'].items()}
            if 'indices' in primitive:
                primitive['indices'] = mapping[primitive['indices']]
            for target in primitive.get('targets', []):
                for key in target:
                    target[key] = mapping[target[key]]
    for skin in doc.get('skins', []):
        if 'inverseBindMatrices' in skin:
            skin['inverseBindMatrices'] = mapping[skin['inverseBindMatrices']]
    for image in doc.get('images', []):
        if 'bufferView' in image:
            image['bufferView'] = view_map[image['bufferView']]
    doc['buffers'][0]['byteLength'] = len(new_binary)
    encoded = json.dumps(doc, separators=(',', ':')).encode()
    encoded += b' ' * (-len(encoded) % 4)
    result = struct.pack('<4sII', b'glTF', 2, 12 + 8 + len(encoded) + 8 + len(new_binary))
    result += struct.pack('<I4s', len(encoded), b'JSON') + encoded
    result += struct.pack('<I4s', len(new_binary), b'BIN\0') + new_binary
    path.write_bytes(result)
    print(path.name, len(raw), len(result))
