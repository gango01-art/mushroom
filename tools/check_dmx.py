"""Regression: repeated binary DMX saves preserve empty strings and UInt widths."""
from io import BytesIO
from vendor import datamodel as dm

model = dm.DataModel('vmap', 40)
root = model.add_element('root', 'CMapRootElement')
model.root = root
root['itemFile'] = ''
root['missingElement'] = None
root['wide'] = dm.UInt64(2 ** 50 + 17)
root['bytes'] = dm.make_array([dm.UInt8(0), dm.UInt8(255)], dm.UInt8)
for _ in range(3):
    model = dm.load(in_file=BytesIO(model.echo('binary', 9)))
    assert model.root['itemFile'] == '' and isinstance(model.root['itemFile'], str)
    assert model.root['missingElement'] is None
    assert model.root['wide'] == 2 ** 50 + 17
    assert list(model.root['bytes']) == [0, 255]
print('DMX round trip OK: empty string stays string, null stays element, UInt8/64 preserved')
